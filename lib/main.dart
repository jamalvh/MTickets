import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure that Firebase is initialized before runApp
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    return MaterialApp(
      theme: ThemeData.dark(),
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/chat',
      routes: {
        '/sign-in': (context) {
          return SignInScreen(
            providers: providers,
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.pushReplacementNamed(context, '/chat');
              }),
            ],
          );
        },
        '/chat': (context) {
          return const ChatPage();
        },
      },
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _collectionRef = FirebaseFirestore.instance.collection("messages");

  final TextEditingController _textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("WorldChat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream:
                  _collectionRef.orderBy("time", descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("There are no messages"));
                }

                return ListView(children: getMessages(snapshot), reverse: true);
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 100,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black26,
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.2,
                    child: Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: TextField(
                          controller: _textFieldController,
                          cursorColor: Colors.blue[700],
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "say something interesting..."),
                          onSubmitted: (value) {
                            if (_textFieldController.text != "") {
                              _collectionRef.add({
                                "senderId":
                                    FirebaseAuth.instance.currentUser?.uid,
                                "text": _textFieldController.text,
                                "time": DateTime.now(),
                              });
                              _textFieldController.text = "";
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_textFieldController.text != "") {
                      _collectionRef.add({
                        "senderId": FirebaseAuth.instance.currentUser?.uid,
                        "text": _textFieldController.text,
                        "time": DateTime.now(),
                      });
                      _textFieldController.text = "";
                    }
                  },
                  child: Container(
                    color: Colors.black26,
                    width: MediaQuery.of(context).size.width * 0.2,
                    height: MediaQuery.of(context).size.width * 0.2,
                    child: const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  getMessages(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data?.docs
        .map(
          (doc) => Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment:
                  FirebaseAuth.instance.currentUser?.uid != doc["senderId"]
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  child:
                      FirebaseAuth.instance.currentUser?.uid != doc["senderId"]
                          ? const Icon(Icons.person_outline_outlined)
                          : Container(),
                ),
                FirebaseAuth.instance.currentUser?.uid != doc["senderId"]
                    ? SizedBox(width: MediaQuery.of(context).size.width * 0.015)
                    : Container(),
                SizedBox(
                    width: MediaQuery.of(context).size.width * 0.35,
                    child: Align(
                      alignment: FirebaseAuth.instance.currentUser?.uid ==
                              doc["senderId"]
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                            color: FirebaseAuth.instance.currentUser?.uid ==
                                    doc["senderId"]
                                ? Colors.blue[700]
                                : Colors.grey.withOpacity(0.2),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(6))),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            doc["text"],
                          ),
                        ),
                      ),
                    )),
                FirebaseAuth.instance.currentUser?.uid == doc["senderId"]
                    ? SizedBox(width: MediaQuery.of(context).size.width * 0.015)
                    : Container(),
                FirebaseAuth.instance.currentUser?.uid == doc["senderId"]
                    ? const Icon(Icons.person)
                    : Container(),
              ],
            ),
          ),
        )
        .toList();
  }
}
