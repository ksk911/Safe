import 'package:flutter/material.dart';

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
