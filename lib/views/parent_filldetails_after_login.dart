import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class ParentDetails extends StatefulWidget {
  const ParentDetails({super.key});

  @override
  State<ParentDetails> createState() => _ParentDetailsState();
}

class _ParentDetailsState extends State<ParentDetails> {
  final String parentId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> childrenLocations = [];
  String? selectedChildId;
  LatLng? parentLocation;
  LatLng? childLocation;
  final MapController _mapController = MapController(); // Add MapController

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _getParentLocation();
    _fetchChildrenLocations();
  }

  /// 🔹 Request & Get Parent's Location
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("❌ Location permission denied.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print("❌ Location permission permanently denied.");
      return;
    }
  }

  Future<void> _getParentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        parentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print("❌ Error getting parent location: $e");
    }
  }

  /// 🔹 Fetch Children's Locations
  Future<void> _fetchChildrenLocations() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Child")
        .where("Parent_ID", isEqualTo: parentId)
        .get();

    setState(() {
      childrenLocations = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?; // Safely cast to Map
        if (data == null) {
          print("⚠️ Document data is null for Child ID: ${doc.id}");
          return {
            "Child_ID": doc.id,
            "Name": "Unknown",
            "Location": null,
          };
        }

        double? latitude =
            data.containsKey("latitude") ? data["latitude"] : null;
        double? longitude =
            data.containsKey("longitude") ? data["longitude"] : null;

        if (latitude != null && longitude != null) {
          return {
            "Child_ID": doc.id,
            "Name": data["Name"] ?? "Unknown",
            "Location": LatLng(latitude, longitude),
          };
        } else {
          print("⚠️ Missing latitude or longitude for Child ID: ${doc.id}");
          return {
            "Child_ID": doc.id,
            "Name": data["Name"] ?? "Unknown",
            "Location": null, // Handle missing coordinates
          };
        }
      }).toList();
    });
  }

  /// 🔹 Approve Sync Request
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Error approving sync request: ${e.toString()}")));
    }
  }

  /// 🔹 Reject Sync Request
  Future<void> rejectSyncRequest(String childId) async {
    try {
      // Ensure the sync request belongs to the current parent
      DocumentSnapshot syncRequestDoc = await FirebaseFirestore.instance
          .collection("SyncRequests")
          .doc(childId)
          .get();

      if (!syncRequestDoc.exists) {
        print("❌ Sync request not found!");
        return;
      }

      String? parentIdInRequest = syncRequestDoc["Parent_ID"];
      if (parentIdInRequest != parentId) {
        print("❌ You do not have permission to reject this sync request.");
        return;
      }

      // Delete the sync request
      await FirebaseFirestore.instance
          .collection("SyncRequests")
          .doc(childId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Sync request rejected successfully!")));
    } catch (e) {
      print("❌ Error rejecting sync request: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Error rejecting sync request: ${e.toString()}")));
    }
  }

  /// 🔹 Adjust Map View to Include Parent and Child Locations
  void _adjustMapView() {
    if (parentLocation != null && childLocation != null) {
      // Calculate the midpoint between parent and child locations
      double midLat = (parentLocation!.latitude + childLocation!.latitude) / 2;
      double midLng =
          (parentLocation!.longitude + childLocation!.longitude) / 2;
      LatLng midpoint = LatLng(midLat, midLng);

      // Calculate the distance between parent and child using Geolocator
      double distance = Geolocator.distanceBetween(
        parentLocation!.latitude,
        parentLocation!.longitude,
        childLocation!.latitude,
        childLocation!.longitude,
      );

      // Adjust zoom level dynamically based on the distance
      double zoomLevel =
          12 - (distance / 10000); // Adjust this formula as needed

      // Move the map to the midpoint and set the zoom level
      _mapController.move(midpoint, zoomLevel);
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
            /// 🔹 Map Box with Parent & Child Locations
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 250, // Adjust the map size
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        mapController: _mapController, // Add MapController
                        options: MapOptions(
                          initialCenter:
                              parentLocation ?? LatLng(20.5937, 78.9629),
                          initialZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          ),
                          MarkerLayer(
                            markers: [
                              if (parentLocation != null)
                                Marker(
                                  point: parentLocation!,
                                  width: 50,
                                  height: 50,
                                  child: const Column(
                                    children: [
                                      Icon(Icons.person_pin_circle,
                                          color: Colors.blue, size: 45),
                                      Text("You",
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              if (childLocation != null)
                                Marker(
                                  point: childLocation!,
                                  width: 50,
                                  height: 50,
                                  child: const Column(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.red, size: 40),
                                      Text("Child",
                                          style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// 🔹 Dropdown & Buttons Inside Rounded Box
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    hint: const Text("Select a Child"),
                    value: selectedChildId,
                    items: childrenLocations
                        .map<DropdownMenuItem<String>>((child) {
                      return DropdownMenuItem<String>(
                        value: child["Child_ID"],
                        child: Text(child["Name"]),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedChildId = value;
                        childLocation = childrenLocations.firstWhere(
                            (child) => child["Child_ID"] == value)["Location"];
                        _adjustMapView(); // Adjust map view when child is selected
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: selectedChildId != null
                            ? () => approveSyncRequest(selectedChildId!)
                            : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text("Approve Sync"),
                      ),
                      ElevatedButton(
                        onPressed: selectedChildId != null
                            ? () => rejectSyncRequest(selectedChildId!)
                            : null,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text("Reject Sync"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* import 'package:flutter/material.dart';
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
 */
