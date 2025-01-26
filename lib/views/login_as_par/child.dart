import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:learningdart/views/login_viewchild.dart";

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
        )
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
                    onPressed: () async {
                      final email = _email.text;
                      final password = _password.text;
                      try {
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email, password: password);
                        print('Parent logged in successfully');
                      } catch (e) {
                        print('Error: $e');
                      }
                    },
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
                    child: Text('Login as Child'),
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
                    () => print("Parent Registration"),
                  ),
                  buildCustomButton(
                    'lib/assets/images/icons8-boy-48.png',
                    'Child Registration',
                    () => print("Child Registration"),
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
