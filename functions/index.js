const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");
const admin = require("firebase-admin");
const axios = require("axios");
const {
    S3Client,
    PutObjectCommand,
    DeleteObjectCommand,
} = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

admin.initializeApp();

// ---------------------------------------------------------
// Secrets
// ---------------------------------------------------------
const PAYMOB_API_KEY = defineSecret("PAYMOB_API_KEY");
const PAYMOB_SECRET_KEY = defineSecret("PAYMOB_SECRET_KEY");
const PAYMOB_HMAC = defineSecret("PAYMOB_HMAC");
const PAYMOB_CARD_INTEGRATION_ID = defineSecret("PAYMOB_CARD_INTEGRATION_ID");
const PAYMOB_IFRAME_ID = defineSecret("PAYMOB_IFRAME_ID");

// ✅ R2 Secrets
const R2_ACCESS_KEY_ID = defineSecret("R2_ACCESS_KEY_ID");
const R2_SECRET_ACCESS_KEY = defineSecret("R2_SECRET_ACCESS_KEY");
const R2_ENDPOINT = defineSecret("R2_ENDPOINT");
const R2_BUCKET = defineSecret("R2_BUCKET");
const R2_PUBLIC_BASE_URL = defineSecret("R2_PUBLIC_BASE_URL");

function requireAuth(request) {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be logged in.");
    }
}

function normalizePhone(p) {
    if (!p) return "+20100000000";
    if (!p.startsWith("+")) return "+2" + p;
    return p;
}

// ---------------------------------------------------------
// Existing R2 Functions
// ---------------------------------------------------------

exports.deleteR2File = onCall(
    {
        region: "us-central1",
        secrets: [
            R2_ACCESS_KEY_ID,
            R2_SECRET_ACCESS_KEY,
            R2_ENDPOINT,
            R2_BUCKET,
            R2_PUBLIC_BASE_URL,
        ],
    },
    async (request) => {
        requireAuth(request);
        const publicUrl = request.data?.publicUrl;

        if (!publicUrl) {
            throw new HttpsError("invalid-argument", "publicUrl is required.");
        }

        const bucket = R2_BUCKET.value();
        const baseUrl = R2_PUBLIC_BASE_URL.value();

        if (!publicUrl.startsWith(baseUrl)) {
            throw new HttpsError(
                "invalid-argument",
                "URL does not belong to this bucket."
            );
        }

        const key = publicUrl.substring(baseUrl.length + 1);

        const s3 = new S3Client({
            region: "auto",
            endpoint: R2_ENDPOINT.value(),
            credentials: {
                accessKeyId: R2_ACCESS_KEY_ID.value(),
                secretAccessKey: R2_SECRET_ACCESS_KEY.value(),
            },
        });

        const command = new DeleteObjectCommand({
            Bucket: bucket,
            Key: key,
        });

        await s3.send(command);
        return { success: true };
    }
);

exports.getR2UploadUrl = onCall(
    {
        region: "us-central1",
        secrets: [
            R2_ACCESS_KEY_ID,
            R2_SECRET_ACCESS_KEY,
            R2_ENDPOINT,
            R2_BUCKET,
            R2_PUBLIC_BASE_URL,
        ],
    },
    async (request) => {
        requireAuth(request);

        const fileName = request.data?.fileName;
        const contentType = request.data?.contentType;
        const propertyId = request.data?.propertyId;

        if (!fileName || !contentType) {
            throw new HttpsError(
                "invalid-argument",
                "fileName and contentType are required."
            );
        }

        const bucket = R2_BUCKET.value();

        const s3 = new S3Client({
            region: "auto",
            endpoint: R2_ENDPOINT.value(),
            credentials: {
                accessKeyId: R2_ACCESS_KEY_ID.value(),
                secretAccessKey: R2_SECRET_ACCESS_KEY.value(),
            },
        });

        const uuid = crypto.randomUUID();
        const folder = propertyId ? `properties/${propertyId}` : "properties";
        const key = `${folder}/${uuid}_${fileName}`;

        const command = new PutObjectCommand({
            Bucket: bucket,
            Key: key,
            ContentType: contentType,
        });

        const uploadUrl = await getSignedUrl(s3, command, {
            expiresIn: 60 * 5,
        });

        const publicUrl = `${R2_PUBLIC_BASE_URL.value()}/${key}`;

        return { uploadUrl, publicUrl, key };
    }
);

// ---------------------------------------------------------
// 🛠 Paymob Helpers (Private)
// ---------------------------------------------------------

async function getPaymobAuthToken(apiKey) {
    try {
        const response = await axios.post("https://accept.paymob.com/api/auth/tokens", {
            api_key: apiKey
        });
        return response.data.token;
    } catch (error) {
        console.error("Paymob Auth Error", error.response?.data || error.message);
        throw new HttpsError("internal", "Payment provider authentication failed.");
    }
}

async function createPaymobOrder(authToken, amountCents, currency, merchantOrderId, items) {
    try {
        const response = await axios.post("https://accept.paymob.com/api/ecommerce/orders", {
            auth_token: authToken,
            delivery_needed: "false",
            amount_cents: amountCents,
            currency: currency,
            merchant_order_id: merchantOrderId,
            items: items || []
        });
        return response.data.id; // Paymob Order ID
    } catch (error) {
        console.error("Paymob Order Error", error.response?.data || error.message);
        throw new HttpsError("internal", "Failed to create payment order.");
    }
}

async function getPaymentKey(authToken, paymobOrderId, amountCents, currency, integrationId, billingData) {
    try {
        const response = await axios.post("https://accept.paymob.com/api/acceptance/payment_keys", {
            auth_token: authToken,
            amount_cents: amountCents,
            expiration: 3600,
            order_id: paymobOrderId,
            billing_data: billingData,
            currency: currency,
            integration_id: integrationId,
            lock_order_when_paid: "false"
        });
        return response.data.token;
    } catch (error) {
        console.error("Paymob Key Error", error.response?.data || error.message);
        throw new HttpsError("internal", "Failed to generate payment key.");
    }
}

// ---------------------------------------------------------
// 🏠 Real Estate Booking System
// ---------------------------------------------------------

/**
 * Function 1: createDepositBooking
 * Creates a booking and deposit payment intent + Paymob Key.
 */
exports.createDepositBooking = onCall(
    {
        region: "us-central1",
        secrets: [
            PAYMOB_API_KEY,
            PAYMOB_HMAC,
            PAYMOB_CARD_INTEGRATION_ID,
            PAYMOB_IFRAME_ID
        ],
    },
    async (request) => {
        requireAuth(request);

        const { propertyId, userInfo } = request.data;
        if (!propertyId || !userInfo) {
            throw new HttpsError("invalid-argument", "propertyId and userInfo are required.");
        }

        const db = admin.firestore();
        const propertyRef = db.collection("properties").doc(propertyId);

        // 1. Validate Property
        const propertySnap = await propertyRef.get();
        if (!propertySnap.exists) {
            throw new HttpsError("not-found", "Property not found.");
        }
        const property = propertySnap.data();

        if (property.bookingEnabled !== true) {
            throw new HttpsError("failed-precondition", "Booking is not enabled for this property.");
        }

        // Allow 'available' (typical flow) or 'approved' (newly added by admin)
        // 2. Validate Property Progress (Commented out to allow booking regardless of status)
        if (property.status !== "available") {
            throw new HttpsError("failed-precondition", `Property is not available. Status: ${property.status}`);
        }

        // 2. Financials
        const finalPrice = property.discountPrice && property.discountPrice > 0
            ? Number(property.discountPrice)
            : Number(property.price);

        const deposit = Number(property.requiredDeposit) || Number(property.deposit) || 0;
        const totalCommission = finalPrice * 0.5;
        const remainingAmount = totalCommission - deposit;

        if (remainingAmount < 0) {
            throw new HttpsError("internal", "Calculated remaining amount is negative.");
        }

        // Check for existing booking
        const existingBooking = await db.collection("bookings")
            .where("userId", "==", request.auth.uid)
            .where("propertyId", "==", propertyId)
            .where("status", "in", ["pending_deposit", "reserved"])
            .get();

        if (!existingBooking.empty) {
            throw new HttpsError("already-exists", "You already have a pending or reserved booking for this property.");
        }

        const userId = request.auth.uid;
        const bookingRef = db.collection("bookings").doc();
        const paymentRef = db.collection("payments").doc();

        const bookingId = bookingRef.id;
        const paymentId = paymentRef.id;

        const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000));

        await db.runTransaction(async (transaction) => {
            const propRef = db.collection("properties").doc(propertyId);
            const propSnap = await transaction.get(propRef);

            if (!propSnap.exists) {
                throw new HttpsError("not-found", "Property not found.");
            }

            const propData = propSnap.data();
            if (propData.status !== "available") { // Only allow if fully available
                throw new HttpsError("failed-precondition", "Property is currently being booked by someone else.");
            }

            // Lock the property
            transaction.update(propRef, {
                status: "locking",
                lockedAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Create Booking
            transaction.set(bookingRef, {
                userId,
                propertyId,
                depositPaid: 0,
                totalCommission,
                remainingAmount,
                status: "pending_deposit",
                userInfo,
                expiresAt: expiresAt,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            // Create Payment
            transaction.set(paymentRef, {
                bookingId,
                type: "deposit",
                amount: deposit,
                status: "pending",
                userId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });

        // 4. Paymob Integration
        const currency = "EGP";
        const amountCents = Math.round(deposit * 100);

        // Prepare Billing Data (Mandatory for Paymob)
        // We try to fill from `userInfo` or defaults
        const billingData = {
            "apartment": "NA",
            "email": userInfo.email || "customer@example.com",
            "floor": "NA",
            "first_name": userInfo.name?.split(" ")[0] || "Customer",
            "street": "NA",
            "building": "NA",
            "phone_number": normalizePhone(userInfo.phone),
            "shipping_method": "NA",
            "postal_code": "NA",
            "city": "NA",
            "country": "EG",
            "last_name": userInfo.name?.split(" ").slice(1).join(" ") || "User",
            "state": "NA"
        };

        const apiKey = PAYMOB_API_KEY.value();
        const integrationId = PAYMOB_CARD_INTEGRATION_ID.value();

        // A. Auth
        const authToken = await getPaymobAuthToken(apiKey);

        // B. Order
        const paymobOrderId = await createPaymobOrder(
            authToken,
            amountCents,
            currency,
            paymentId, // merchant_order_id
            [] // items
        );

        // C. Payment Key
        const paymentToken = await getPaymentKey(
            authToken,
            paymobOrderId,
            amountCents,
            currency,
            integrationId,
            billingData
        );

        // D. Return Token & internal IDs
        return {
            bookingId,
            paymentId,
            deposit,
            remainingAmount,
            paymentToken,
            iframeId: PAYMOB_IFRAME_ID.value() // Default or secret
        };
    }
);

/**
 * Function 2: paymobWebhook
 */
exports.paymobWebhook = onRequest(
    {
        region: "us-central1",
        secrets: [PAYMOB_HMAC],
    },
    async (req, res) => {
        const hmacSecret = PAYMOB_HMAC.value();
        const receivedHmac = req.query.hmac;
        const data = req.body.obj || req.body;

        if (!data || !receivedHmac) {
            return res.status(400).send("Missing data");
        }

        const fields = [
            "amount_cents",
            "created_at",
            "currency",
            "id",
            "order.id",
            "pending",
            "source_data.pan",
            "source_data.sub_type",
            "success"
        ];

        const raw = fields.map(f => {
            const value = f.split('.').reduce((o, i) => o?.[i], data);
            return (value === undefined || value === null) ? "" : value.toString();
        }).join("");

        const calc = crypto.createHmac("sha512", hmacSecret).update(raw).digest("hex");

        if (calc !== receivedHmac) {
            return res.status(401).send("Invalid HMAC");
        }

        const paymentId = data.order?.merchant_order_id;
        const success = data.success === true;

        if (!paymentId) return res.status(200).send("No ID");

        const db = admin.firestore();
        const paymentRef = db.collection("payments").doc(paymentId);

        try {
            await db.runTransaction(async (t) => {
                const paymentSnap = await t.get(paymentRef);
                if (!paymentSnap.exists) {
                    // Payment doc might not exist if creation failed or race condition. 
                    // We throw to catch block.
                    throw new Error("Payment Document Not Found");
                }

                const payment = paymentSnap.data();

                // Idempotency Check
                if (payment.status === "paid" || (payment.externalId && payment.externalId === data.id.toString())) {
                    console.log("Duplicate Webhook/Transaction - Already Processed");
                    return;
                }

                if (success) {
                    // Update Payment
                    t.update(paymentRef, {
                        status: "paid",
                        externalId: data.id.toString(),
                        paymobOrderId: data.order?.id?.toString(),
                        paidAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    // Booking Update
                    const bookingRef = db.collection("bookings").doc(payment.bookingId);
                    const bSnap = await t.get(bookingRef);
                    if (bSnap.exists) {
                        const booking = bSnap.data();
                        const pRef = db.collection("properties").doc(booking.propertyId);

                        if (payment.type === "deposit") {
                            const exp = new Date();
                            exp.setDate(exp.getDate() + 7);
                            t.update(bookingRef, {
                                status: "reserved",
                                depositPaid: payment.amount,
                                expiresAt: admin.firestore.Timestamp.fromDate(exp)
                            });
                            // Update from 'locking' to 'reserved'
                            t.update(pRef, { status: "reserved" });
                        } else {
                            t.update(bookingRef, { status: "completed" });
                            t.update(pRef, { status: "sold" });
                        }
                    }
                } else {
                    // Failed
                    t.update(paymentRef, {
                        status: "failed",
                        externalId: data.id.toString()
                    });
                }
            });

            res.status(200).send("OK");
        } catch (e) {
            console.error("Webhook Error:", e);
            res.status(500).send("Error");
        }
    }
);

/**
 * Function 3: createRemainingPayment
 */
exports.createRemainingPayment = onCall(
    {
        region: "us-central1",
        secrets: [
            PAYMOB_API_KEY,
            PAYMOB_CARD_INTEGRATION_ID,
            PAYMOB_IFRAME_ID
        ]
    },
    async (request) => {
        requireAuth(request);

        const { bookingId } = request.data;
        const db = admin.firestore();
        const bookingRef = db.collection("bookings").doc(bookingId);
        const paymentRef = db.collection("payments").doc(); // Create ref early for transaction
        const paymentId = paymentRef.id;

        const { remainingAmount, userInfo } = await db.runTransaction(async (transaction) => {
            const bookingSnap = await transaction.get(bookingRef);
            if (!bookingSnap.exists) {
                throw new HttpsError("not-found", "Booking not found");
            }
            const booking = bookingSnap.data();

            if (booking.userId !== request.auth.uid) {
                throw new HttpsError("permission-denied", "Not yours");
            }
            if (booking.status !== "reserved") {
                throw new HttpsError("failed-precondition", "Not reserved or already processing");
            }
            // Check expiry just in case
            if (booking.expiresAt && booking.expiresAt.toMillis() < Date.now()) {
                throw new HttpsError("failed-precondition", "Booking expired");
            }

            // Lock booking status
            transaction.update(bookingRef, { status: "paying_remaining" });

            // Create Payment
            transaction.set(paymentRef, {
                bookingId,
                type: "remaining",
                amount: booking.remainingAmount,
                status: "pending",
                userId: request.auth.uid,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return { remainingAmount: booking.remainingAmount, userInfo: booking.userInfo };
        });

        // Generate Paymob Token for Remaining (outside transaction)
        const amountCents = Math.round(remainingAmount * 100);
        const currency = "EGP";
        const apiKey = PAYMOB_API_KEY.value();
        const integrationId = PAYMOB_CARD_INTEGRATION_ID.value();

        const billingData = {
            "apartment": "NA",
            "email": userInfo?.email || "customer@example.com",
            "floor": "NA",
            "first_name": userInfo?.name?.split(" ")[0] || "Customer",
            "street": "NA",
            "building": "NA",
            "phone_number": normalizePhone(userInfo?.phone),
            "shipping_method": "NA",
            "postal_code": "NA",
            "city": "NA",
            "country": "EG",
            "last_name": userInfo?.name?.split(" ").slice(1).join(" ") || "User",
            "state": "NA"
        };

        const authToken = await getPaymobAuthToken(apiKey);
        const orderId = await createPaymobOrder(authToken, amountCents, currency, paymentId);
        const paymentToken = await getPaymentKey(authToken, orderId, amountCents, currency, integrationId, billingData);

        return {
            paymentId,
            amount: remainingAmount,
            paymentToken,
            iframeId: PAYMOB_IFRAME_ID.value()
        };
    }
);

/**
 * Function 4: expireBookings
 */
exports.expireBookings = onSchedule(
    {
        schedule: "every 1 hours",
        timeZone: "Africa/Cairo",
        region: "us-central1"
    },
    async (event) => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();
        const snap = await db.collection("bookings")
            .where("status", "in", ["reserved", "paying_remaining"])
            .where("expiresAt", "<", now)
            .get();

        if (snap.empty) return;

        const batch = db.batch();
        const propIds = new Set();

        snap.docs.forEach((doc) => {
            batch.update(doc.ref, { status: "expired" });
            if (doc.data().propertyId) propIds.add(doc.data().propertyId);
        });

        for (const pid of propIds) {
            batch.update(db.collection("properties").doc(pid), { status: "available" });
        }

        await batch.commit();
    }
);
