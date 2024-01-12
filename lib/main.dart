import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Global
var _targetCollectionRef = FirebaseFirestore.instance.collection("messages");
String recieverId = "null";

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
    return MaterialApp(
      theme: ThemeData.dark(),
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/chat',
      routes: {
        '/sign-in': (context) {
          return const SignInPage();
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
  final db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: GestureDetector(
          onTap: () => setState(() {}),
          child: Row(
            children: [
              Text(
                "M",
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[700]),
              ),
              const Text(
                "Tickets 🚀",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Do nothing
            },
            label: const Text(
              "1.1k",
              style: TextStyle(color: Color.fromARGB(255, 202, 196, 208)),
            ),
            icon: const Icon(
              Icons.group,
              color: Color.fromARGB(255, 202, 196, 208),
            ),
          ),
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/sign-in');
            },
            icon: const Icon(Icons.logout),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.015),
        ],
      ),
      body: Row(
        children: [
          Container(
            width: 200,
            color: const Color.fromARGB(255, 23, 22, 25),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        color: _targetCollectionRef.id == 'messages'
                            ? Colors.yellow[700]?.withOpacity(0.15)
                            : Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                              _targetCollectionRef.id == 'messages'
                                  ? Icons.group
                                  : Icons.group_outlined,
                              color: _targetCollectionRef.id == 'messages'
                                  ? Colors.amber
                                  : const Color.fromARGB(255, 230, 225, 229)),
                          title: Text(
                            "Exchange",
                            style: TextStyle(
                                fontSize: 16,
                                color: _targetCollectionRef.id == 'messages'
                                    ? Colors.amber
                                    : const Color.fromARGB(255, 230, 225, 229)),
                          ),
                          onTap: () {
                            setState(() {
                              _targetCollectionRef = FirebaseFirestore.instance
                                  .collection("messages");
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, top: 5.0),
                        child: Text(
                          "Direct Messages",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('dms')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (!snapshot.hasData ||
                              snapshot.data?.docs.isEmpty == true) {
                            return const Center(child: Text(""));
                          }

                          return Column(
                            children: [
                              for (var dm in snapshot.data!.docs)
                                FutureBuilder<List<Widget>>(
                                  future: getDMList(dm),
                                  builder: (context, innerSnapshot) {
                                    if (innerSnapshot.connectionState ==
                                        ConnectionState.done) {
                                      return Column(
                                        children: innerSnapshot.data ??
                                            [
                                              const Text(
                                                  "Widgets not available")
                                            ],
                                      );
                                    } else {
                                      return Container();
                                    }
                                  },
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text(
                    "Account",
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          // ignore: prefer_const_constructors
          ChatWidget(),
        ],
      ),
    );
  }

  Future<List<Widget>> getDMList(
      QueryDocumentSnapshot<Map<String, dynamic>> dm) async {
    List<Widget> userWidgets = [];

    try {
      var userDoc =
          await FirebaseFirestore.instance.collection('users').doc(dm.id).get();

      if (userDoc.exists) {
        var firstName = userDoc.data()?['firstName'] ?? 'DefaultFirstName';
        var lastName = userDoc.data()?['lastName'] ?? 'DefaultFirstName';
        userWidgets.add(
          Container(
            color: _targetCollectionRef ==
                    db
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('dms')
                        .doc(dm.id)
                        .collection('dmMessages')
                ? Colors.yellow[700]?.withOpacity(0.15)
                : Colors.transparent,
            child: ListTile(
              leading: Icon(
                _targetCollectionRef ==
                        db
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('dms')
                            .doc(dm.id)
                            .collection('dmMessages')
                    ? Icons.person
                    : Icons.person_outline,
                color: _targetCollectionRef ==
                        db
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('dms')
                            .doc(dm.id)
                            .collection('dmMessages')
                    ? Colors.amber
                    : const Color.fromARGB(255, 230, 225, 229),
              ),
              title: Text(
                "$firstName $lastName",
                style: TextStyle(
                  fontSize: 16,
                  overflow: TextOverflow.ellipsis,
                  color: _targetCollectionRef ==
                          db
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection('dms')
                              .doc(dm.id)
                              .collection('dmMessages')
                      ? Colors.amber
                      : const Color.fromARGB(255, 230, 225, 229),
                ),
              ),
              onTap: () {
                setState(() {
                  _targetCollectionRef = db
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('dms')
                      .doc(dm.id)
                      .collection('dmMessages');
                  recieverId = dm.id;
                });
              },
            ),
          ),
        );
      } else {
        userWidgets.add(const SizedBox(
          height: 0,
          child: ListTile(
            title: Text("User document not found"),
            contentPadding: EdgeInsets.zero,
          ),
        ));
      }
    } catch (e) {
      // Handle errors here
      userWidgets.add(const Text("Error fetching user data"));
    }

    return userWidgets;
  }
}

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _textFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _targetCollectionRef
                  .orderBy("time", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("Nothing, yet!"));
                }

                var messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return buildMessageWidget(messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: Row(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.width * 0.2,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      color: Colors.black26,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0, bottom: 5),
                      child: TextField(
                        controller: _textFieldController,
                        cursorColor: Colors.blue[700],
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "say something interesting..."),
                        onSubmitted: (value) {
                          if (_textFieldController.text != "") {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('dms')
                                .doc(recieverId)
                                .set({});
                            _targetCollectionRef.add({
                              "senderId":
                                  FirebaseAuth.instance.currentUser?.uid,
                              "text": _textFieldController.text,
                              "time": DateTime.now(),
                            });
                            // Add to reciever's dmMessages fb folder (unless exchange)
                            if (_targetCollectionRef.id != 'messages') {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(recieverId)
                                  .collection('dms')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .set({});
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(recieverId) // reciever id
                                  .collection('dms')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .collection('dmMessages')
                                  .add({
                                "senderId":
                                    FirebaseAuth.instance.currentUser?.uid,
                                "text": _textFieldController.text,
                                "time": DateTime.now(),
                              });
                            }

                            _textFieldController.text = "";
                          }
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_textFieldController.text != "") {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .collection('dms')
                          .doc(recieverId)
                          .set({});
                      _targetCollectionRef.add({
                        "senderId": FirebaseAuth.instance.currentUser?.uid,
                        "text": _textFieldController.text,
                        "time": DateTime.now(),
                      });
                      // Add to reciever's dmMessages fb folder (unless exchange)
                      if (_targetCollectionRef.id != 'messages') {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(recieverId)
                            .collection('dms')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .set({});
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(recieverId) // reciever id
                            .collection('dms')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('dmMessages')
                            .add({
                          "senderId": FirebaseAuth.instance.currentUser?.uid,
                          "text": _textFieldController.text,
                          "time": DateTime.now(),
                        });
                      }

                      _textFieldController.text = "";
                    }
                  },
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMessageWidget(DocumentSnapshot<Object?> doc) {
    var senderId = doc["senderId"];

    return FutureBuilder<String>(
      future: getFirstAndLastName(doc, senderId),
      builder: (context, snapshotFirstName) {
        if (snapshotFirstName.connectionState == ConnectionState.done) {
          var senderFirstName = snapshotFirstName.data;

          return Padding(
            padding:
                const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
            child: Row(
              mainAxisAlignment:
                  FirebaseAuth.instance.currentUser?.uid != senderId
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  child: FirebaseAuth.instance.currentUser?.uid != senderId
                      ? GestureDetector(
                          onTapDown: (details) {
                            showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                  details.globalPosition.dx,
                                  details.globalPosition.dy,
                                  details.globalPosition.dx,
                                  details.globalPosition.dy),
                              items: [
                                PopupMenuItem(
                                  child: const Text("Message"),
                                  onTap: () {
                                    setState(() {
                                      _targetCollectionRef = FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(FirebaseAuth
                                              .instance.currentUser?.uid)
                                          .collection('dms')
                                          .doc(doc["senderId"])
                                          .collection('dmMessages');
                                      recieverId = doc["senderId"];
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                          child: const Icon(Icons.person_outline_outlined),
                        )
                      : Container(),
                ),
                FirebaseAuth.instance.currentUser?.uid != senderId
                    ? SizedBox(width: MediaQuery.of(context).size.width * 0.015)
                    : Container(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: Align(
                    alignment:
                        FirebaseAuth.instance.currentUser?.uid == senderId
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment:
                          FirebaseAuth.instance.currentUser?.uid == senderId
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child:
                              FirebaseAuth.instance.currentUser?.uid != senderId
                                  ? Text(
                                      senderFirstName!,
                                      style: const TextStyle(fontSize: 10),
                                    )
                                  : Container(),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          decoration: BoxDecoration(
                            color: FirebaseAuth.instance.currentUser?.uid ==
                                    senderId
                                ? Colors.yellow[700]?.withOpacity(0.15)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(6)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              doc["text"],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FirebaseAuth.instance.currentUser?.uid == senderId
                    ? SizedBox(width: MediaQuery.of(context).size.width * 0.015)
                    : Container(),
                FirebaseAuth.instance.currentUser?.uid == senderId
                    ? const Icon(Icons.person)
                    : Container(),
              ],
            ),
          );
        } else {
          return Container(); // or a loading indicator
        }
      },
    );
  }

  Future<String> getFirstAndLastName(var doc, String senderId) async {
    if (FirebaseAuth.instance.currentUser?.uid == senderId) {
      return "";
    }
    var senderDocSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get();

    var senderFirstName = senderDocSnapshot.data()?["firstName"];
    return senderFirstName ?? "";
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  TextEditingController regFirstNameTEC = TextEditingController();
  TextEditingController regLastNameTEC = TextEditingController();
  TextEditingController regEmailTEC = TextEditingController();
  TextEditingController regPasswordTEC = TextEditingController();
  String regErrorMessage = "";
  String regSuccessMessage = "";

  TextEditingController logEmailTEC = TextEditingController();
  TextEditingController logPasswordTEC = TextEditingController();
  String logErrorMessage = "";
  String logSuccessMessage = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: GestureDetector(
          onTap: () => setState(() {}),
          child: Row(
            children: [
              Text(
                "M",
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[700]),
              ),
              const Text(
                "Tickets 🚀",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * .15,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Column(
                          // Registering Widget
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: regFirstNameTEC,
                                    cursorColor: Colors.yellow[700],
                                    decoration: const InputDecoration(
                                      hintText: "First Name",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(4),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 251, 192, 45),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: regLastNameTEC,
                                    cursorColor: Colors.yellow[700],
                                    decoration: const InputDecoration(
                                      hintText: "Last Name",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(4),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color:
                                              Color.fromARGB(255, 251, 192, 45),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 310,
                              child: TextField(
                                controller: regEmailTEC,
                                cursorColor: Colors.yellow[700],
                                decoration: const InputDecoration(
                                  hintText: "Email",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 251, 192, 45),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: 310,
                              child: TextField(
                                controller: regPasswordTEC,
                                obscureText: true,
                                cursorColor: Colors.yellow[700],
                                decoration: const InputDecoration(
                                  hintText: "Password",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromARGB(255, 251, 192, 45),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 310,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Register user
                                      if (regCheckValidCredentials()) {
                                        registerUser();
                                      }
                                    },
                                    style: ButtonStyle(
                                      shape: MaterialStatePropertyAll(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          side: const BorderSide(
                                              color: Color.fromARGB(
                                                  255, 251, 192, 45)),
                                        ),
                                      ),
                                      backgroundColor:
                                          const MaterialStatePropertyAll(
                                        Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      'Register',
                                      style:
                                          TextStyle(color: Colors.yellow[700]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 310,
                                  child: Text(
                                    regErrorMessage,
                                    style:
                                        TextStyle(color: Colors.red.shade500),
                                  ),
                                ),
                                Text(
                                  regSuccessMessage,
                                  style:
                                      TextStyle(color: Colors.green.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.1),
                      Column(
                        // Login Widget
                        children: [
                          SizedBox(
                            width: 310,
                            child: TextField(
                              controller: logEmailTEC,
                              cursorColor: Colors.yellow[700],
                              decoration: const InputDecoration(
                                hintText: "Email",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(4),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 251, 192, 45),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 310,
                            child: TextField(
                              controller: logPasswordTEC,
                              obscureText: true,
                              cursorColor: Colors.yellow[700],
                              decoration: const InputDecoration(
                                hintText: "Password",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(4),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromARGB(255, 251, 192, 45),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 310,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (logCheckValidCredentials()) {
                                      loginUser();
                                    }
                                  },
                                  style: ButtonStyle(
                                    shape: MaterialStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        side: const BorderSide(
                                            color: Color.fromARGB(
                                                255, 251, 192, 45)),
                                      ),
                                    ),
                                    backgroundColor:
                                        const MaterialStatePropertyAll(
                                      Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(color: Colors.yellow[700]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 310,
                                child: Text(
                                  logErrorMessage,
                                  style: TextStyle(color: Colors.red.shade500),
                                ),
                              ),
                              Text(
                                logSuccessMessage,
                                style: TextStyle(color: Colors.green.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  bool regCheckValidCredentials() {
    if (regFirstNameTEC.text.isEmpty) {
      setState(() {
        regErrorMessage = 'Please enter your first name.';
        regSuccessMessage = '';
      });
      return false;
    }
    if (regLastNameTEC.text.isEmpty) {
      setState(() {
        regErrorMessage = 'Please enter your last name.';
        regSuccessMessage = '';
      });
      return false;
    }

    if (regEmailTEC.text.isEmpty) {
      setState(() {
        regErrorMessage = 'Please enter your email.';
        regSuccessMessage = '';
      });
      return false;
    }
    if (!isValidEmail(regEmailTEC.text)) {
      setState(() {
        regErrorMessage = 'Please enter a valid email address.';
        regSuccessMessage = '';
      });
      return false;
    }

    if (regPasswordTEC.text.isEmpty) {
      setState(() {
        regErrorMessage = 'Please enter a password.';
        regSuccessMessage = '';
      });
      return false;
    }
    setState(() {
      regErrorMessage = '';
    });

    return true;
  }

  bool logCheckValidCredentials() {
    if (logEmailTEC.text.isEmpty) {
      setState(() {
        logErrorMessage = 'Please enter your email.';
        logSuccessMessage = '';
      });
      return false;
    }
    if (!isValidEmail(logEmailTEC.text)) {
      setState(() {
        logErrorMessage = 'Please enter a valid email address.';
        logSuccessMessage = '';
      });
      return false;
    }

    if (logPasswordTEC.text.isEmpty) {
      setState(() {
        logErrorMessage = 'Please enter a password.';
        logSuccessMessage = '';
      });
      return false;
    }
    setState(() {
      logErrorMessage = '';
    });

    return true;
  }

  void registerUser() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: regEmailTEC.text, password: regPasswordTEC.text);
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        "firstName": regFirstNameTEC.text,
        "lastName": regLastNameTEC.text,
      });
      setState(() {
        regSuccessMessage = 'Success!';
      });
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/chat');
    } catch (e) {
      setState(() {
        regErrorMessage = '$e';
        regSuccessMessage = '';
      });
    }
  }

  void loginUser() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: logEmailTEC.text, password: logPasswordTEC.text);
      setState(() {
        regSuccessMessage = 'Success!';
      });
      // ignore: use_build_context_synchronously
      Navigator.pushReplacementNamed(context, '/chat');
    } catch (e) {
      setState(() {
        logErrorMessage = '$e';
        logSuccessMessage = '';
      });
    }
  }
}
