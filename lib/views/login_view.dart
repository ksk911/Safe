import 'package:learningdart/main.dart';
import "package:firebase_auth/firebase_auth.dart";
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:learningdart/firebase_options.dart';
import 'package:path/path.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  bool ispressed = false;

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
            child: Text(
              'LOGIN',
              //textAlign: TextAlign.center,
            )),
        backgroundColor: const Color.fromARGB(255, 251, 64, 145),
      ),
      body: FutureBuilder(
        future: Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Column(
                children: [
                  TextField(
                    controller: _email,
                    /* enableSuggestions: false, */
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(hintText: 'TYPE YOUR EMAIL'),
                  ),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration:
                        InputDecoration(hintText: 'Enter your password'),
                  ),
                  OutlinedButton(
                      onPressed: () async {
                        //print('helo world');

                        final email = _email.text;
                        final password = _password.text;
                        //print(password);
                        try {
                          final usercredential = await FirebaseAuth.instance
                              .signInWithEmailAndPassword(
                                  email: email, password: password);
                          print(usercredential);
                        } catch (e) {
                          print('there was an error');
                          print(e.runtimeType);
                        }
                      },
                      child: const Text('LOGIN!!')),
                  OutlinedButton(
                    onPressed: () {
                      //bool ispressed = false;
                      setState(() {
                        ispressed = true;
                      });

                      Future.delayed(Duration(milliseconds: 10), () {
                        setState(() {
                          ispressed = false;
                        });
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterView(),
                        ),
                      );

                      //style:OutlinedButton.styleFrom(backgroundColor: ispressed?Colors.green:Colors.blueAccent);
                    },
                    style: OutlinedButton.styleFrom(
                        //primary: Colors.blue,
                        foregroundColor: Colors.white,
                        //backgroundColor: Colors.blueAccent,
                        backgroundColor:
                            ispressed ? Colors.green : Colors.blueAccent,
                        shadowColor: Colors.black12),
                    child: Text('Register Now'),
                  ),
                ],
              );
            default:
              return const Text('Loading ...');
          }
        },
      ),
    );
  }
}
