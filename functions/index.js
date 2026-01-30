const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.createDepositBooking = functions.https.onCall(async (data, context) => {

  const propertyId = data.propertyId;

  if (!propertyId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "propertyId required"
    );
  }

  const db = admin.firestore();

  const snap = await db.collection("properties").doc(propertyId).get();

  if (!snap.exists) {
    throw new functions.https.HttpsError("not-found", "Property not found");
  }

  const property = snap.data();

  const price = property.price;
  const deposit = property.deposit;

  const commission = price * 0.5;
  const remaining = commission - deposit;

  return {
    price,
    deposit,
    commission,
    remaining
  };
});
