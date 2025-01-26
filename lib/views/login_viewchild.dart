import 'package:learningdart/main.dart';
import "package:firebase_auth/firebase_auth.dart";
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:learningdart/firebase_options.dart';

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

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
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
        title: Align(
          alignment: Alignment.center,
          child: Text('LOGIN'),
        ),
        backgroundColor: const Color.fromARGB(255, 251, 64, 145),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Login Heading
                      Text(
                        'Login for Child',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),

                      // Login Fields
                      TextField(
                        controller: _email,
                        autocorrect: false,
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
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Login Button
                      ElevatedButton(
                        onPressed: () async {
                          final email = _email.text;
                          final password = _password.text;

                          try {
                            final userCredential = await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                    email: email, password: password);
                            print('Logged in as child: ${userCredential.user}');
                          } catch (e) {
                            print('Child Login Error: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Login'),
                      ),
                      SizedBox(height: 40),

                      // Registration Buttons for Parent and Child
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildCustomButton(
                            'lib/assets/images/icons8-parents-48.png',
                            'Parent Registration',
                            () {
                              print("Parent's Registration");
                              // Add navigation to Parent Registration page
                            },
                          ),
                          buildCustomButton(
                            'lib/assets/images/icons8-boy-48.png',
                            'Child Registration',
                            () {
                              print('Child Registration');
                              // Add navigation to Child Registration page
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            default:
              return const Center(child: Text('Loading ...'));
          }
        },
      ),
    );
  }
}
