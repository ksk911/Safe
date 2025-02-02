import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildLocationView extends StatefulWidget {
  const ChildLocationView({super.key});

  @override
  State<ChildLocationView> createState() => _ChildLocationViewState();
}

class _ChildLocationViewState extends State<ChildLocationView> {
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentIdController = TextEditingController();

  Position? _currentPosition;
  String? _currentAddress;
  bool _isParentVerified = false;
  String _parentDetailsMessage = "";
  String _syncedParentName = "";
  String _syncedParentId = "";
  LatLng? _mapLocation;

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentIdController.dispose();
    super.dispose();
  }

  /// 🔹 Get Current Location
  Future<void> _getLocation() async {
    try {
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _mapLocation = LatLng(position.latitude, position.longitude);
      });

      print(
          "📍 Latitude: ${position.latitude}, Longitude: ${position.longitude}");
      _getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      print("❌ Error getting location: $e");
    }
  }

  /// 🔹 Get Address from LatLng
  Future<void> _getAddressFromLatLng(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();

      setState(() {
        _currentAddress =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });

      print("🏡 Address: $_currentAddress");
    } catch (e) {
      print("❌ Error getting address: $e");
    }
  }

  /// 🔹 Sync Parent Details and Store in Child Document
  Future<void> _syncParent() async {
    String enteredParentName = _parentNameController.text.trim();
    String enteredParentId = _parentIdController.text.trim();

    if (enteredParentName.isEmpty || enteredParentId.isEmpty) {
      print("⚠️ Enter both Parent Name and Parent ID.");
      return;
    }

    try {
      DocumentSnapshot parentDoc = await FirebaseFirestore.instance
          .collection("Parent")
          .doc(enteredParentId)
          .get();

      if (parentDoc.exists) {
        String storedName = parentDoc['Name'];
        String storedId = parentDoc['Parent_ID'];

        if (storedName == enteredParentName && storedId == enteredParentId) {
          print("✅ Parent Synced Successfully!");

          // ✅ Store Parent ID inside Child Document
          String childId = FirebaseAuth.instance.currentUser!.uid;
          await FirebaseFirestore.instance
              .collection("Child")
              .doc(childId)
              .update({
            "Parent_ID": enteredParentId,
          });

          setState(() {
            _isParentVerified = true;
            _syncedParentName = enteredParentName;
            _syncedParentId = enteredParentId;
            _parentDetailsMessage = "Parent synced successfully!";
          });
        } else {
          print("❌ Parent details do not match.");
        }
      } else {
        print("❌ Parent not found.");
      }
    } catch (e) {
      print("❌ Error syncing parent: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Child Location")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _parentNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Parent Name',
                hintText: 'Enter Name (e.g., Ramesh Singh)',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _parentIdController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Parent ID',
                hintText: 'Enter Parent ID',
              ),
            ),
            const SizedBox(height: 20),

            /// 🔹 Button: Sync Parent
            ElevatedButton(
              onPressed: _syncParent,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("Sync Parent ID"),
            ),

            if (_isParentVerified) ...[
              const SizedBox(height: 20),

              /// 🔹 Button: Display Parent Info (Only if Synced)
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                    "Parent Synced: $_syncedParentName ($_syncedParentId)"),
              ),
            ],

            const SizedBox(height: 20),

            /// 🔹 Button: Get Location
            ElevatedButton(
              onPressed: _getLocation,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Get Location"),
            ),

            const SizedBox(height: 20),

            /// 🔹 Display Map
            Expanded(
              child: _mapLocation != null
                  ? FlutterMap(
                      options: MapOptions(
                        initialCenter: _mapLocation!,
                        initialZoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _mapLocation!,
                              width: 80,
                              height: 80,
                              child: const Icon(Icons.location_on,
                                  size: 40, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const Center(child: Text("Location not available")),
            ),
          ],
        ),
      ),
    );
  }
}
