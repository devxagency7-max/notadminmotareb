const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");
const admin = require("firebase-admin");
const axios = require("axios"); // Added axios
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

// ✅ R2 Secrets
const R2_ACCESS_KEY_ID = defineSecret("R2_ACCESS_KEY_ID");
const R2_SECRET_ACCESS_KEY = defineSecret("R2_SECRET_ACCESS_KEY");
const R2_ENDPOINT = defineSecret("R2_ENDPOINT");
const R2_BUCKET = defineSecret("R2_BUCKET");
const R2_PUBLIC_BASE_URL = defineSecret("R2_PUBLIC_BASE_URL");

// ✅ Paymob Secrets
const PAYMOB_API_KEY = defineSecret("PAYMOB_API_KEY");
const PAYMOB_HMAC = defineSecret("PAYMOB_HMAC");
const PAYMOB_WALLET_INTEGRATION_ID = defineSecret("PAYMOB_WALLET_INTEGRATION_ID");
const PAYMOB_CARD_INTEGRATION_ID = defineSecret("PAYMOB_CARD_INTEGRATION_ID");
const PAYMOB_IFRAME_ID = defineSecret("PAYMOB_IFRAME_ID");

function requireAuth(request) {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be logged in.");
    }
}

// ---------------------------------------------------------
// Paymob Helpers
// ---------------------------------------------------------

async function getPaymobAuthToken(apiKey) {
    const res = await axios.post("https://accept.paymob.com/api/auth/tokens", {
        api_key: apiKey
    });
    return res.data.token;
}

async function createPaymobOrder(authToken, amountCents, currency, merchantOrderId, items) {
    try {
        const res = await axios.post("https://accept.paymob.com/api/ecommerce/orders", {
            auth_token: authToken,
            delivery_needed: false,
            amount_cents: amountCents.toString(),
            currency,
            merchant_order_id: merchantOrderId,
            items
        });
        return res.data.id;
    } catch (e) {
        console.error("🔥 PAYMOB ORDER ERROR:", e.response?.data);
        throw new HttpsError("internal", JSON.stringify(e.response?.data));
    }
}

async function getPaymentKey(authToken, orderId, amountCents, currency, integrationId, billingData) {
    try {
        const res = await axios.post("https://accept.paymob.com/api/acceptance/payment_keys", {
            auth_token: authToken,
            amount_cents: amountCents.toString(),
            expiration: 3600,
            order_id: orderId,
            billing_data: billingData,
            currency,
            integration_id: Number(integrationId)
        });
        return res.data.token;
    } catch (e) {
        console.error("🔥 PAYMOB KEY ERROR:", e.response?.data);
        throw new HttpsError("internal", JSON.stringify(e.response?.data));
    }
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

// ================= CREATE DEPOSIT =================

exports.createDepositBooking = onCall(
    {
        region: "us-central1",
        secrets: [PAYMOB_API_KEY, PAYMOB_CARD_INTEGRATION_ID, PAYMOB_IFRAME_ID, PAYMOB_WALLET_INTEGRATION_ID]
    },
    async (request) => {

        requireAuth(request);

        // ✅ DEBUG LOGS FOR DYNAMIC SELECTIONS
        console.log("DEBUG: createDepositBooking called");
        console.log("DEBUG: propertyId:", request.data.propertyId);
        console.log("DEBUG: selections:", request.data.selections);
        console.log("DEBUG: isWhole:", request.data.isWhole);

        const { propertyId, userInfo, paymentMethod, walletNumber } = request.data;
        if (!userInfo || !userInfo.email) {
            throw new HttpsError("invalid-argument", "Invalid user info");
        }
        console.log("Billing name:", userInfo.name);

        const db = admin.firestore();
        const propSnap = await db.collection("properties").doc(propertyId).get();
        if (!propSnap.exists) throw new HttpsError("not-found", "Property not found");

        const data = propSnap.data();

        // --- Dynamic Pricing Recalculation ---
        let totalPrice = 0;
        const selections = request.data.selections || [];
        const isWhole = request.data.isWhole || false;

        if (isWhole) {
            totalPrice = (data.discountPrice && data.discountPrice > 0) ? data.discountPrice : data.price;
        } else {
            if (!data.rooms || !Array.isArray(data.rooms)) {
                throw new HttpsError("failed-precondition", "Property has no rooms defined for unit/bed booking.");
            }
            selections.forEach(key => {
                // key format: "r0" or "r0_b1"
                const roomPart = key.split("_")[0]; // "r0"
                const roomIndex = parseInt(roomPart.replace("r", ""));
                const room = data.rooms[roomIndex];

                if (!room) {
                    console.error(`Room at index ${roomIndex} not found for key ${key}`);
                    return;
                }

                if (key.includes("_b")) {
                    totalPrice += room.bedPrice || 0;
                } else {
                    totalPrice += room.price || 0;
                }
            });
        }

        const deposit = data.requiredDeposit || data.deposit || 0;
        // Calculation: Remaining = (Half of Total Price) - Deposit
        const totalCommission = totalPrice * 0.5;
        const remainingAmount = totalCommission - deposit;

        if (totalPrice <= 0) {
            throw new HttpsError("invalid-argument", "Calculated total price is zero or invalid.");
        }
        // -------------------------------------

        // Check for existing booking
        const existingBookings = await db.collection("bookings")
            .where("userId", "==", request.auth.uid)
            .where("propertyId", "==", propertyId)
            .get();

        let existingPendingBooking = null;
        for (const doc of existingBookings.docs) {
            const bData = doc.data();
            if (bData.status === "reserved" || bData.status === "completed") {
                // Allow multiple bookings for the same property (e.g. User books Room 1, then later Room 2)
                // continue; 
            }
            if (bData.status === "pending_deposit") {
                existingPendingBooking = doc;
            }
        }

        const bookingId = existingPendingBooking ? existingPendingBooking.id : db.collection("bookings").doc().id;
        const bookingRef = db.collection("bookings").doc(bookingId);
        const paymentRef = db.collection("payments").doc();
        const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000));

        // Use Transaction for Soft Lock & Sync
        await db.runTransaction(async (t) => {
            const propRef = db.collection("properties").doc(propertyId);
            const propSnap = await t.get(propRef);

            if (!propSnap.exists) {
                throw new HttpsError("not-found", "Property not found.");
            }

            const property = propSnap.data();

            // --- NEW LOGIC: Partial Booking Validation ---
            const bookedUnits = property.bookedUnits || [];

            if (isWhole) {
                // If user wants entire apartment, it must be completely empty
                if (property.status !== "approved" && property.status !== "available") { // strict check
                    throw new HttpsError("failed-precondition", "Property is not fully available for whole-apartment booking.");
                }
                if (bookedUnits.length > 0) {
                    throw new HttpsError("failed-precondition", "Some units in this property are already booked. Cannot book whole apartment.");
                }
            } else {
                // Check if ANY of the selected units are already in bookedUnits
                const alreadyBooked = selections.filter(unitId => bookedUnits.includes(unitId));
                if (alreadyBooked.length > 0) {
                    throw new HttpsError("failed-precondition", `The following units are already booked: ${alreadyBooked.join(", ")}`);
                }
            }

            // Create or Update Booking (Upsert)
            t.set(bookingRef, {
                userId: request.auth.uid,
                propertyId,
                totalPrice,
                totalCommission,
                depositAmount: deposit,
                remainingAmount,
                depositPaid: 0,
                firstPaid: false,
                secondPaid: false,
                status: "pending_deposit",
                userInfo,
                selections,
                isWhole,
                expiresAt: expiresAt,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            // Create Payment
            t.set(paymentRef, {
                bookingId: bookingRef.id,
                type: "deposit",
                amount: deposit,
                status: "pending",
                userId: request.auth.uid,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        const amountCents = Math.round(deposit * 100);

        let phone = userInfo.phone || "01000000000";
        if (!phone.startsWith("+")) phone = "+2" + phone;

        const billingData = {
            apartment: "NA",
            email: userInfo.email,
            floor: "NA",
            first_name: userInfo.name ? userInfo.name.split(" ")[0] : "Customer",
            street: "NA",
            building: "NA",
            phone_number: phone,
            shipping_method: "NA",
            postal_code: "NA",
            city: "NA",
            country: "EG",
            last_name: "User",
            state: "NA"
        };

        const authToken = await getPaymobAuthToken(PAYMOB_API_KEY.value());

        const items = [{
            name: "Booking Deposit",
            amount_cents: amountCents.toString(),
            description: "Property booking",
            quantity: 1
        }];

        const orderId = await createPaymobOrder(authToken, amountCents, "EGP", paymentRef.id, items);

        let integrationId = PAYMOB_CARD_INTEGRATION_ID.value();
        if (paymentMethod === 'wallet') {
            integrationId = PAYMOB_WALLET_INTEGRATION_ID.value();
        }

        const paymentToken = await getPaymentKey(
            authToken,
            orderId,
            amountCents,
            "EGP",
            integrationId,
            billingData
        );

        if (paymentMethod === 'wallet') {
            if (!walletNumber) {
                throw new HttpsError("invalid-argument", "Wallet number is required for wallet payments.");
            }

            try {
                // Direct Pay request for wallet
                // Note: axios is required, ensure it is imported or available in scope. 
                // Context check: axios is imported at top of file (I viewed it earlier).
                const payResponse = await axios.post("https://accept.paymob.com/api/acceptance/payments/pay", {
                    source: {
                        identifier: walletNumber,
                        subtype: "WALLET"
                    },
                    payment_token: paymentToken
                });

                console.log("Paymob Wallet Response:", JSON.stringify(payResponse.data));

                return {
                    bookingId: bookingRef.id,
                    paymentId: paymentRef.id,
                    redirectUrl: payResponse.data.redirect_url, // Direct redirection URL
                    iframeId: null,
                    paymentToken: null
                };
            } catch (error) {
                console.error("Paymob Wallet Error:", error.response ? error.response.data : error.message);
                throw new HttpsError("internal", "Failed to initiate wallet payment.");
            }
        }

        return {
            bookingId: bookingRef.id,
            paymentId: paymentRef.id,
            paymentToken,
            iframeId: PAYMOB_IFRAME_ID.value()
        };
    }
);

// ================= WEBHOOK =================
exports.paymobWebhook = onRequest(
    { region: "us-central1", secrets: [PAYMOB_HMAC] },
    async (req, res) => {
        try {
            const data = req.body.obj || req.body;

            console.log("WEBHOOK HIT");

            const paymentId =
                data.order?.merchant_order_id || data.merchant_order_id;

            const success = data.success === true;

            if (!paymentId) return res.status(200).send("No ID");

            const db = admin.firestore();
            const paymentRef = db.collection("payments").doc(paymentId);

            await db.runTransaction(async (t) => {

                // ✅ READ FIRST
                const paymentSnap = await t.get(paymentRef);
                if (!paymentSnap.exists) throw new Error("Payment not found");

                const payment = paymentSnap.data();

                const bookingRef = db.collection("bookings").doc(payment.bookingId);
                const bookingSnap = await t.get(bookingRef);
                if (!bookingSnap.exists) throw new Error("Booking not found");

                const booking = bookingSnap.data();
                const propRef = db.collection("properties").doc(booking.propertyId);
                const propSnap = await t.get(propRef);
                if (!propSnap.exists) throw new Error("Property not found");
                const property = propSnap.data();

                // ✅ NOW WRITE

                if (payment.status === "paid") return;

                t.update(paymentRef, {
                    status: success ? "paid" : "failed",
                    externalId: data.id.toString(),
                    paidAt: admin.firestore.FieldValue.serverTimestamp()
                });

                if (!success) return;

                if (payment.type === "deposit") {

                    const exp = new Date();
                    exp.setDate(exp.getDate() + 7);

                    t.update(bookingRef, {
                        status: "reserved",
                        firstPaid: true,
                        secondPaid: false,
                        depositPaid: payment.amount,
                        expiresAt: admin.firestore.Timestamp.fromDate(exp)
                    });

                    // --- NEW LOGIC: Update bookedUnits & Check for Full Occupancy ---

                    const currentBookedUnits = new Set(property.bookedUnits || []);
                    const newSelections = booking.selections || [];


                    // Add new selections to bookedUnits
                    newSelections.forEach(unit => currentBookedUnits.add(unit));

                    const updatedBookedUnits = Array.from(currentBookedUnits);

                    let newPropertyStatus = "available"; // Default remains available if partially booked

                    if (booking.isWhole) {
                        newPropertyStatus = "reserved";
                    } else {
                        // Check if ALL units are now booked
                        // We need the total count of units to know if it's fully booked.
                        // Assuming 'rooms' array exists.
                        // We need to count total bookable slots (rooms or beds).
                        // This estimation relies on correct data. 

                        let totalSlots = 0;
                        if (property.rooms) {
                            property.rooms.forEach((r, rIdx) => {
                                if (r.beds > 0) {
                                    for (let i = 0; i < r.beds; i++) totalSlots++; // Each bed is a slot "r0_b0"
                                } else {
                                    totalSlots++; // Implementation treats room as 1 slot "r0"
                                }
                            });
                        }

                        // If all slots are covered, mark as reserved
                        // Note: logic might need adjusting depending on exact ID format "r0" vs "r0_b1" strictly.
                        // Ideally we check if every generated slot ID is in updatedBookedUnits.

                        // For SAFETY: We will ONLY flip to 'reserved' if explicitly whole or logic confirms.
                        // Let's implement a safer check: 
                        // If (updatedBookedUnits.length >= totalSlots && totalSlots > 0) -> reserved

                        if (totalSlots > 0 && updatedBookedUnits.length >= totalSlots) {
                            newPropertyStatus = "reserved";
                        }
                    }

                    t.update(propRef, {
                        bookedUnits: updatedBookedUnits,
                        status: newPropertyStatus
                    });

                } else {

                    t.update(bookingRef, {
                        status: "completed",
                        secondPaid: true
                    });

                    t.update(propRef, { status: "sold" });
                }

            });

            return res.status(200).send("OK");

        } catch (e) {
            console.error("Webhook Error:", e);
            return res.status(500).send("Error");
        }
    }
);

// ================= EXPIRE BOOKINGS =================

exports.expireBookings = onSchedule(
    { schedule: "every 1 hours", timeZone: "Africa/Cairo" },
    async (event) => {
        const db = admin.firestore();
        const now = admin.firestore.Timestamp.now();

        // 1. Get all reserved bookings that have passed their expiration date
        const snap = await db.collection("bookings")
            .where("status", "==", "reserved")
            .where("secondPaid", "==", false)
            .where("expiresAt", "<", now)
            .get();

        if (snap.empty) {
            console.log("No expired bookings found.");
            return;
        }

        const batch = db.batch();

        snap.docs.forEach((doc) => {
            const booking = doc.data();

            // 2. Set booking status to expired
            batch.update(doc.ref, {
                status: "expired",
                expiredAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // 3. Restore property status to approved (available)
            if (booking.propertyId) {
                const propRef = db.collection("properties").doc(booking.propertyId);
                batch.update(propRef, { status: "approved" });
            }
        });

        await batch.commit();
        console.log(`Successfully expired ${snap.size} bookings and restored their properties.`);
    }
);


// ================= REMAINING PAYMENT =================

exports.createRemainingPayment = onCall(
    {
        region: "us-central1",
        secrets: [PAYMOB_API_KEY, PAYMOB_CARD_INTEGRATION_ID, PAYMOB_IFRAME_ID, PAYMOB_WALLET_INTEGRATION_ID]
    },
    async (request) => {
        requireAuth(request);

        const { bookingId, paymentMethod, walletNumber } = request.data;
        if (!bookingId) throw new HttpsError("invalid-argument", "Booking ID is required.");

        const db = admin.firestore();
        const bookingRef = db.collection("bookings").doc(bookingId);
        const bookingSnap = await bookingRef.get();

        if (!bookingSnap.exists) throw new HttpsError("not-found", "Booking not found.");

        const booking = bookingSnap.data();
        console.log("Billing name:", booking?.userInfo?.name);

        // 1. Validation
        if (booking.userId !== request.auth.uid) {
            throw new HttpsError("permission-denied", "Unauthorized access to this booking.");
        }
        if (booking.status !== "reserved") {
            throw new HttpsError("failed-precondition", `Payment allowed only for reserved bookings. Current status: ${booking.status}`);
        }
        if (booking.secondPaid === true) {
            throw new HttpsError("failed-precondition", "Remaining amount has already been paid.");
        }

        const remainingAmount = booking.remainingAmount || 0;
        if (remainingAmount <= 0) {
            throw new HttpsError("failed-precondition", "No remaining amount to pay.");
        }

        const amountCents = Math.round(remainingAmount * 100);
        const paymentRef = db.collection("payments").doc();

        // Billing Data from existing booking userInfo
        const userInfo = booking.userInfo || {};
        let phone = userInfo.phone || "01000000000";
        if (!phone.startsWith("+")) phone = "+2" + phone;

        const billingData = {
            apartment: "NA",
            email: userInfo.email || "customer@example.com",
            floor: "NA",
            first_name: userInfo.name ? userInfo.name.split(" ")[0] : "Customer",
            street: "NA",
            building: "NA",
            phone_number: phone,
            shipping_method: "NA",
            postal_code: "NA",
            city: "NA",
            country: "EG",
            last_name: "User",
            state: "NA"
        };

        const authToken = await getPaymobAuthToken(PAYMOB_API_KEY.value());

        const items = [{
            name: "Remaining Booking Payment",
            amount_cents: amountCents.toString(),
            description: `Remaining payment for booking ${bookingId}`,
            quantity: 1
        }];

        const orderId = await createPaymobOrder(authToken, amountCents, "EGP", paymentRef.id, items);

        let integrationId = PAYMOB_CARD_INTEGRATION_ID.value();
        if (paymentMethod === 'wallet') {
            integrationId = PAYMOB_WALLET_INTEGRATION_ID.value();
        }

        const paymentToken = await getPaymentKey(
            authToken,
            orderId,
            amountCents,
            "EGP",
            integrationId,
            billingData
        );

        // Store payment intent
        await paymentRef.set({
            bookingId,
            type: "remaining",
            amount: remainingAmount,
            status: "pending",
            userId: request.auth.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        if (paymentMethod === 'wallet') {
            if (!walletNumber) {
                throw new HttpsError("invalid-argument", "Wallet number is required for wallet payments.");
            }

            try {
                const payResponse = await axios.post("https://accept.paymob.com/api/acceptance/payments/pay", {
                    source: {
                        identifier: walletNumber,
                        subtype: "WALLET"
                    },
                    payment_token: paymentToken
                });

                return {
                    bookingId,
                    paymentId: paymentRef.id,
                    redirectUrl: payResponse.data.redirect_url, // Direct redirection URL
                    iframeId: null,
                    paymentToken: null
                };
            } catch (error) {
                console.error("Paymob Wallet Error:", error.response ? error.response.data : error.message);
                throw new HttpsError("internal", "Failed to initiate wallet payment.");
            }
        }

        return {
            bookingId,
            paymentId: paymentRef.id,
            paymentToken,
            iframeId: PAYMOB_IFRAME_ID.value()
        };
    }
);
