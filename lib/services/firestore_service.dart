import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ticket_booking_app/models/event_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ Get current user details from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await _db.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          return snapshot.data() as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
    return null;
  }

  /// ✅ Update user profile details in Firestore
  Future<void> updateUserData(Map<String, dynamic> newData) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set(newData, SetOptions(merge: true));
        print("✅ User data updated successfully for: ${user.uid}");
      }
    } catch (e) {
      print("❌ Error updating user data: $e");
    }
  }

  /// ✅ Save FCM token for push notifications
  Future<void> saveFCMToken(String token, String toke) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).update({'fcmToken': token});
        print("✅ FCM Token updated for user: ${user.uid}");
      }
    } catch (e) {
      print("❌ Error saving FCM Token: $e");
    }
  }

  /// ✅ Fetch events as a Stream
  Stream<List<Event>> getEvents() {
    return _db.collection('events').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Event.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
