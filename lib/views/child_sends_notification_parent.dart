import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChildNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// 🔹 Send Notification to Parent
  Future<void> sendSyncRequestToParent(String parentId, String childId) async {
    try {
      DocumentSnapshot parentDoc = await FirebaseFirestore.instance
          .collection("Parent")
          .doc(parentId)
          .get();

      if (!parentDoc.exists) {
        print("❌ Parent not found!");
        return;
      }

      String? parentFcmToken = parentDoc["Notification_Token"];
      if (parentFcmToken == null) {
        print("⚠️ Parent FCM Token is missing!");
        return;
      }

      await FirebaseFirestore.instance
          .collection("SyncRequests")
          .doc(childId)
          .set({
        "Child_ID": childId,
        "Parent_ID": parentId,
        "status": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      });

      await _firebaseMessaging.sendMessage(
        to: parentFcmToken,
        data: {
          "title": "Child Sync Request",
          "body": "Your child wants to sync with you. Approve in the app.",
        },
      );

      print("✅ Notification sent to Parent!");
    } catch (e) {
      print("❌ Error sending sync request notification: $e");
    }
  }
}
