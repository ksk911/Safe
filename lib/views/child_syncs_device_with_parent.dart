import 'package:flutter/material.dart';

class child_view_after_login_adddevice extends StatefulWidget {
  const child_view_after_login_adddevice({super.key});

  @override
  State<child_view_after_login_adddevice> createState() =>
      _ParentDetailsState();
}

class _ParentDetailsState extends State<child_view_after_login_adddevice> {
  final TextEditingController _Details_Parent = TextEditingController();

  @override
  void dispose() {
    _Details_Parent.dispose();
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
              controller: _Details_Parent,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Parent Name',
                hintText: 'Enter Name(e.g., Ramesh Singh)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("Parent Name: ${_Details_Parent.text}");
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
