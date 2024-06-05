import 'dart:convert';
import 'user.dart';
import 'main.dart';
import 'package:flutter/material.dart';
import 'shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  UserDetailScreen({required this.user});

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with WidgetsBindingObserver {
  bool isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance?.window.viewInsets.bottom ?? 0;
    setState(() {
      isKeyboardVisible = bottomInset > 0;
    });
  }

  void _openModal(BuildContext context) {
    final _formKey = GlobalKey<FormState>(); // Add a form key
    // Create text editing controllers for the message fields
    final TextEditingController titleController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Enable full-screen modal
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey, // Assign the form key
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Write a message to ${widget.user.name}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller:
                          titleController, // Set the controller for the title field
                      decoration: InputDecoration(
                        hintText: 'Title',
                      ),
                      maxLength: 255,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      controller:
                          bodyController, // Set the controller for the body field
                      decoration: InputDecoration(
                        hintText: 'Content',
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter content';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          //Check if there's JWT
                          String? token = await MySharedPreferences.getToken();
                          print(token);
                          if (token != null && token != "") {
                            Map<String, dynamic> payload =
                                JwtDecoder.decode(token!);
                            final String sender_email = payload['email'];
                            final String recipient_email = widget.user.email;
                            // Retrieve the values from the text fields
                            final String title = titleController.text;
                            final String body = bodyController.text;
                            // Try to send the message using the retrieved values
                            final url =
                                Uri.parse('http://192.168.1.42:8080/sendMsg');
                            final headers = {
                              'Authorization': 'Bearer ${token}',
                              'Content-Type': 'application/json'
                            };
                            final reqBody = json.encode({
                              "title": title,
                              "body": body,
                              "sender_email": sender_email,
                              "recipient_email": recipient_email
                            });

                            final response = await http.post(
                              url,
                              headers: headers,
                              body: reqBody,
                            );

                            if (response.statusCode == 201) {
                              //Se envió el mensaje exitosamente
                              titleController.text=="";
                              bodyController.text=="";
                              Navigator.pop(context);
                            } else {
                              print(response.statusCode);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error sending message, please try again.'),
                                ),
                              );
                            }
                          } else {
                            //No hay JWT, volver a iniciar sesión
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MyHomePage(title: 'Messaging App'),
                              ),
                            );
                          }
                        }
                      },
                      child: Text('Send'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Details'),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: MemoryImage(base64Decode(widget.user.image)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  widget.user.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    _openModal(context); // Open the modal
                  },
                  icon: Icon(
                    Icons.email,
                    size: 30,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'E-mail: ${widget.user.email}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Phone number: ${widget.user.phone}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              'Job: ${widget.user.job}',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
