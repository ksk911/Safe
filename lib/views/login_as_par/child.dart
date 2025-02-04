import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learningdart/views/parent_filldetails_after_login.dart';
import 'package:learningdart/views/login_viewchild.dart';
import 'package:learningdart/views/reg_child.dart';
import 'package:learningdart/views/parent_reg.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔹 Added Firebase Messaging import

Widget buildCustomButton(String imagePath, String title, Function()? onTap) {
  return InkWell(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
        SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ],
    ),
  );
}

class CustomButtonDemo extends StatefulWidget {
  const CustomButtonDemo({super.key});

  @override
  State<CustomButtonDemo> createState() => _CustomButtonDemoState();
}

class _CustomButtonDemoState extends State<CustomButtonDemo> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // 🔹 Function to update FCM token on login
  Future<void> updateParentTokenOnLogin(String parentId) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();

    await FirebaseFirestore.instance.collection('Parent').doc(parentId).update({
      'Notification_Token': fcmToken, // ✅ Update token on login
    });
  }

  Future<void> _loginParent() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final String uid = userCredential.user!.uid;

      // ✅ Step 2: Cross-check the Parent Table in Firestore
      DocumentSnapshot parentDoc =
          await FirebaseFirestore.instance.collection('Parent').doc(uid).get();

      if (parentDoc.exists) {
        // ✅ Parent exists, update FCM token and navigate to the next page
        await updateParentTokenOnLogin(uid); // 🔹 Update FCM token
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ParentDetails()),
        );
        print('Parent logged in successfully');
      } else {
        // ❌ User is NOT a parent, log them out and show error
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Access Denied: You are not a parent. Please Register First')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Check your credentials.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Child Safe App'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 251, 64, 145),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                'Login for Parents',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _loginParent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Login as Parent'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginView()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Login as Child ??'),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildCustomButton(
                    'lib/assets/images/icons8-parents-48.png',
                    'Parent Registration',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterParent()),
                      );
                    },
                  ),
                  buildCustomButton(
                    'lib/assets/images/icons8-boy-48.png',
                    'Child Registration',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterChild()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
