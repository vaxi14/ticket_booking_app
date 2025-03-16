const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")("your_secret_key"); // Replace with your Stripe secret key

admin.initializeApp();

// 🚀 Stripe Payment Intent Function
exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  try {
    const { amount, currency } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
    });

    res.json({ clientSecret: paymentIntent.client_secret });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// 🔔 Firebase Cloud Function to Send Push Notifications on Ticket Booking
exports.sendBookingNotification = functions.firestore
  .document("bookings/{bookingId}")  // Trigger when a new booking is created
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const userId = data.userId; // Get the user who booked the ticket

    if (!userId) {
      console.log("No userId found in the booking document.");
      return;
    }

    // Fetch the user's FCM token from Firestore
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    const userData = userDoc.data();
    const userToken = userData?.fcmToken;  // Ensure users collection has 'fcmToken'

    if (!userToken) {
      console.log("No FCM token found for user:", userId);
      return;
    }

    // Create the notification message
    const message = {
      notification: {
        title: "Ticket Confirmed 🎟️",
        body: `Your ticket for ${data.eventName} is confirmed!`,
      },
      token: userToken,
    };

    // Send the notification
    try {
      await admin.messaging().send(message);
      console.log("Push notification sent successfully!");
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });
