import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:learningdart/views/databasestructure.dart';

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
  bool _isLocationSharing = false;
  LatLng? _mapLocation;
  bool _isParentVerified = false;
  String _parentDetailsMessage = "";

  @override
  void dispose() {
    _parentNameController.dispose();
    _parentIdController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permission denied.");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission is required.")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Location permission permanently denied. Go to settings.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Location permission is permanently denied. Please enable it in settings.",
            ),
          ),
        );
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print("Location permission granted. Fetching location...");

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
          _mapLocation = LatLng(position.latitude, position.longitude);
        });

        print(
            "Latitude: ${position.latitude}, Longitude: ${position.longitude}");

        _getAddressFromLatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting location: $e")),
      );
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();

      setState(() {
        _currentAddress =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
    } catch (e) {
      print("Error getting address: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error getting address: $e")),
      );
    }
  }

  void _toggleLocationSharing() {
    setState(() {
      _isLocationSharing = !_isLocationSharing;
    });

    if (_isLocationSharing) {
      _getLocation();
    }
    print("Getting location...");
  }

  Future<void> _syncParent() async {
    String enteredParentName = _parentNameController.text.trim();
    String enteredParentId = _parentIdController.text.trim();

    if (enteredParentName.isEmpty || enteredParentId.isEmpty) {
      setState(() {
        _parentDetailsMessage = "Please enter both Parent Name and Parent ID.";
        _isParentVerified = false;
      });
      return;
    }

    try {
      DocumentSnapshot parentDoc = await FirebaseFirestore.instance
          .collection('Parent')
          .doc(enteredParentId)
          .get();

      if (parentDoc.exists) {
        String storedName = parentDoc['Name'];
        String storedId = parentDoc['Parent_ID'];

        if (storedName == enteredParentName && storedId == enteredParentId) {
          setState(() {
            _isParentVerified = true;
            _parentDetailsMessage = "Parent synced successfully!";
          });
        } else {
          setState(() {
            _isParentVerified = false;
            _parentDetailsMessage = "Parent details do not match.";
          });
        }
      } else {
        setState(() {
          _isParentVerified = false;
          _parentDetailsMessage = "Parent not found.";
        });
      }
    } catch (e) {
      print("Error syncing parent: $e");
      setState(() {
        _isParentVerified = false;
        _parentDetailsMessage = "Error syncing parent.";
      });
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
                hintText: 'Enter Parent ID (e.g., Ayfp98ddlnv)',
              ),
            ),
            const SizedBox(height: 20),

            // Button to Sync Parent
            ElevatedButton(
              onPressed: _syncParent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text("Sync Parent ID"),
            ),

            // Display parent verification result
            if (_parentDetailsMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  _parentDetailsMessage,
                  style: TextStyle(
                    color: _isParentVerified ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Button to Toggle Location Sharing
            ElevatedButton(
              onPressed: _toggleLocationSharing,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLocationSharing ? Colors.green : Colors.red,
              ),
              child: Text(
                _isLocationSharing ? "Location Active ✅" : "Enable Location 📍",
              ),
            ),

            const SizedBox(height: 20),

            //firestore structure button retrieval

            // Display Current Address
            if (_currentAddress != null)
              Text(
                "Current Address: $_currentAddress",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

            const SizedBox(height: 20),

            // Display Map
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
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _mapLocation!,
                              width: 80,
                              height: 80,
                              child: const Icon(
                                Icons.location_on,
                                size: 40,
                                color: Colors.red,
                              ),
                            )
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
