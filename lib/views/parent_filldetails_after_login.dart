import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentDetails extends StatefulWidget {
  const ParentDetails({super.key});

  @override
  State<ParentDetails> createState() => _ParentDetailsState();
}

class _ParentDetailsState extends State<ParentDetails> {
  final String parentId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _childZoneController = TextEditingController();

  @override
  void dispose() {
    _childZoneController.dispose();
    super.dispose();
  }

  /// 🔹 Approve Sync Request & Link Child to Parent
  Future<void> approveSyncRequest(String childId) async {
    try {
      await FirebaseFirestore.instance.collection("Child").doc(childId).update({
        "Parent_ID": parentId,
      });

      await FirebaseFirestore.instance
          .collection("Parent")
          .doc(parentId)
          .update({
        "Children": FieldValue.arrayUnion([childId]),
      });

      await FirebaseFirestore.instance
          .collection("SyncRequests")
          .doc(childId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Sync request approved successfully!")));
    } catch (e) {
      print("❌ Error approving sync request: $e");
    }
  }

  /// 🔹 Save Safe Zone for the Child
  Future<void> setChildSafeZone() async {
    String safeZone = _childZoneController.text.trim();
    if (safeZone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Please enter a safe zone name.")));
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("Parent")
          .doc(parentId)
          .update({
        "Safe_Zone": safeZone,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Safe Zone '$safeZone' updated successfully!")));

      _childZoneController.clear();
    } catch (e) {
      print("❌ Error setting safe zone: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 🔹 Safe Zone Input Field
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Set Safe Zone for Child",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _childZoneController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Child Zone",
                        hintText: "Enter zone (e.g., School, Park)",
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: setChildSafeZone,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
                      child: const Text("Save Safe Zone"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 Sync Requests Section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("SyncRequests")
                    .where("Parent_ID", isEqualTo: parentId)
                    .where("status", isEqualTo: "pending")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No pending sync requests."));
                  }

                  var requests = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      var request = requests[index];
                      String childId = request["Child_ID"];

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text("Sync Request from Child: $childId"),
                          trailing: ElevatedButton(
                            onPressed: () => approveSyncRequest(childId),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            child: const Text("Approve"),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}







/* import 'package:flutter/material.dart';

class ParentDetails extends StatefulWidget {
  const ParentDetails({super.key});

  @override
  State<ParentDetails> createState() => _ParentDetailsState();
}

class _ParentDetailsState extends State<ParentDetails> {
  final TextEditingController _childZoneController = TextEditingController();

  @override
  void dispose() {
    _childZoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Parent Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _childZoneController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Child Zone',
                hintText: 'Enter zone (e.g., School, Park)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("Child Zone: ${_childZoneController.text}");
              },
              child: const Text(
                "Submit",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 */