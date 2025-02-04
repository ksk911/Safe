import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:learningdart/views/reg_child.dart';
import 'package:learningdart/views/login_as_par/child.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔹 Added Firebase Messaging import

class RegisterParent extends StatefulWidget {
  const RegisterParent({Key? key}) : super(key: key);

  @override
  State<RegisterParent> createState() => _RegisterParentState();
}

class _RegisterParentState extends State<RegisterParent> {
  //final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _email;
  /*  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); */
  late final TextEditingController _password;
  late final TextEditingController _name;
  bool _isLoading = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _name = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  // 🔹 Updated registerParent function with FCM token integration
  Future<void> registerParent() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final name = _name.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Auth: Create a user and get UID
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      String parentId = userCredential.user!.uid;

      // 🔹 Fetch FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Firestore: Write parent details including Notification_Token
      await FirebaseFirestore.instance.collection('Parent').doc(parentId).set({
        'Parent_ID': parentId,
        'Name': name,
        'Email': email,
        'Password': password,
        'Notification_Token': fcmToken, // ✅ Store FCM Token
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomButtonDemo()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent registered successfully!')),
      );

      // Clear the input fields
      _email.clear();
      _password.clear();
      _name.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Parent'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registerParent,
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}







/* import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:learningdart/views/reg_child.dart';
import 'package:learningdart/views/login_as_par/child.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegisterParent extends StatefulWidget {
  const RegisterParent({Key? key}) : super(key: key);

  @override
  State<RegisterParent> createState() => _RegisterParentState();
}

class _RegisterParentState extends State<RegisterParent> {
  //final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _email;
  /*  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(); */
  late final TextEditingController _password;
  late final TextEditingController _name;
  bool _isLoading = false;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _name = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  /* Future<void> registerParent() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final name = _name.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Auth: Create a user and get UID
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      String parentId = userCredential.user!.uid;

      // Firestore: Write parent details to the 'Parent' collection
      await FirebaseFirestore.instance.collection('Parent').doc(parentId).set({
        'Parent_ID': parentId,
        'Name': name,
        'Email': email,
        'Password': password,
      });
      /* Navigator.pushReplacementNamed(context, '/child'); */

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomButtonDemo()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent registered successfully!')),
      );

      // Clear the input fields
      _email.clear();
      _password.clear();
      _name.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  } */

  Future<void> registerParent() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    final name = _name.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Auth: Create a user and get UID
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      String parentid = userCredential.user!.uid;

      // Firestore: Write only basic parent details to the 'Parent' collection
      await FirebaseFirestore.instance.collection('Parent').doc(parentid).set({
        'Parent_ID': parentid,
        'Name': name,
        'Email': email,
        'Password': password,
        // Do not include Safe_Zone here; add it later
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CustomButtonDemo()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parent registered successfully!')),
      );

      // Clear the input fields
      _email.clear();
      _password.clear();
      _name.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Parent'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registerParent,
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}
 */