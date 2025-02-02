import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learningdart/views/login_viewchild.dart';

class RegisterChild extends StatefulWidget {
  const RegisterChild({Key? key}) : super(key: key);

  @override
  State<RegisterChild> createState() => _RegisterChildState();
}

class _RegisterChildState extends State<RegisterChild> {
  late final TextEditingController _email;
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

  Future<void> registerChild() async {
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
      String Child_ID = userCredential.user!.uid;

      // Firestore: Store child details under 'Children' collection
      await FirebaseFirestore.instance.collection('Child').doc(Child_ID).set({
        'Child_ID': Child_ID,
        'Name': name,
        'Email': email,
        'Password': password, // Consider encrypting passwords before storing
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Child registered successfully!')),
      );

      // Clear input fields
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
        title: const Text('Register Child'),
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
                    onPressed: () async {
                      await registerChild();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginView()),
                      );
                    },
                    child: const Text('Register')),
          ],
        ),
      ),
    );
  }
}
