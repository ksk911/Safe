import 'package:cloud_firestore/cloud_firestore.dart';

class ChildNotificationService {
  /// 🔹 Send Notification to Parent
  Future<void> sendSyncRequestToParent(String parentId, String childId) async {
    try {
      // Fetch parent document
      DocumentSnapshot parentDoc = await FirebaseFirestore.instance
          .collection("Parent")
          .doc(parentId)
          .get();

      if (!parentDoc.exists) {
        print("❌ Parent not found!");
        return;
      }

      // Retrieve Parent Notification Token
      final data = parentDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        print("❌ Parent document data is null!");
        return;
      }

      String? parentFcmToken = data["Notification_Token"] as String?;
      if (parentFcmToken == null || parentFcmToken.isEmpty) {
        print("⚠️ Parent FCM Token is missing or empty!");
        return;
      }

      // ✅ Store sync request in Firestore
      await FirebaseFirestore.instance
          .collection("SyncRequests")
          .doc(childId)
          .set({
        "Child_ID": childId,
        "Parent_ID": parentId,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ Send FCM notification using Firestore
      await sendPushNotification(parentFcmToken, childId);

      print("✅ Notification sent to Parent!");
    } catch (e) {
      print("❌ Error sending sync request notification: $e");
    }
  }

  /// 🔹 Send Push Notification using Firestore
  Future<void> sendPushNotification(
      String parentFcmToken, String childId) async {
    try {
      await FirebaseFirestore.instance.collection("Notifications").add({
        "to": parentFcmToken,
        "notification": {
          "title": "Child Sync Request",
          "body": "Your child wants to sync with you. Approve in the app.",
        },
        "data": {
          "childId": childId,
          "type": "sync_request",
        },
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("✅ Push notification stored successfully!");
    } catch (e) {
      print("❌ Error sending push notification: $e");
    }
  }
}
/* import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChildNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// 🔹 Send Notification to Parent
  Future<void> sendSyncRequestToParent(String parentId, String childId) async {
    try {
      // Fetch parent document
      DocumentSnapshot parentDoc = await FirebaseFirestore.instance
          .collection("Parent")
          .doc(parentId)
          .get();

      if (!parentDoc.exists) {
        print("❌ Parent not found!");
        return;
      }

      // Safely retrieve data and check for Notification_Token
      final data = parentDoc.data() as Map<String, dynamic>?;
      if (data == null) {
        print("❌ Parent document data is null!");
        return;
      }

      String? parentFcmToken = data.containsKey("Notification_Token")
          ? data["Notification_Token"] as String?
          : null;

      if (parentFcmToken == null || parentFcmToken.isEmpty) {
        print("⚠️ Parent FCM Token is missing or empty!");
        return;
      }

      // Store sync request in Firestore
      await FirebaseFirestore.instance
          .collection("SyncRequests")
          .doc(childId)
          .set({
        "Child_ID": childId,
        "Parent_ID": parentId,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // ✅ Prevents overwriting issues

      // Send notification
      if (parentFcmToken.isNotEmpty) {
        await _firebaseMessaging.sendMessage(
          to: parentFcmToken,
          data: {
            "title": "Child Sync Request",
            "body": "Your child wants to sync with you. Approve in the app.",
          },
        );
        print("✅ Notification sent to Parent!");
      } else {
        print("⚠️ Parent FCM Token is invalid or missing!");
      }
    } catch (e) {
      print("❌ Error sending sync request notification: $e");
    }
  }
} */
