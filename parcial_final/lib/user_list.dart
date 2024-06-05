import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'shared_preferences.dart';
import 'main.dart';
import 'user.dart';
import 'user_profile.dart';

void _logout(BuildContext context) async {
  String? token = await MySharedPreferences.getToken();
  print(token);
  final url = Uri.parse('http://192.168.1.42:8080/logout');
  final headers = {'Authorization': 'Bearer ${token}'};
  print(headers);

  final response = await http.get(
    url,
    headers: headers,
  );

  if (response.statusCode == 200) {
    // Si el servidor retornó 200 OK
    // Navigate to the login page
    print('Successfully logged out');
  } else {
    // De lo contrario, throw exception
    // Mostrar snackbar con mensaje de error
    print("Error en cerrar la sesión");
  }
  await MySharedPreferences.clearToken();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MyHomePage(title: 'Messaging App'),
    ),
  );
}

//HOMEPAGE
class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  List<User> userList = []; // List to store the retrieved users

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Fetch users when the screen is initialized
  }

  void fetchUsers() async {
    String? token = await MySharedPreferences.getToken();
    if (token != null && token != "") {
      Map<String, dynamic> payload = JwtDecoder.decode(token!);
      String userEmail = payload['email'];
      final url = Uri.parse('http://192.168.1.42:8080/users/${userEmail}');
      final headers = {'Authorization': 'Bearer $token'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // If the request is successful
        final List<dynamic> responseData = json.decode(response.body);
        final List<User> users =
            responseData.map((user) => User.fromJson(user)).toList();

        setState(() {
          userList = users;
        });
      } else {
        // If the request fails
        print('Error fetching users: ${response.statusCode}');
      }
    } else {
      print("Se debe renovar la sesión");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(title: 'Messaging App'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Messaging App'),
            expandedHeight: 50,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff6A5BF2),
                      Color(0xff5AAC69),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.exit_to_app),
                padding: EdgeInsets.only(right: 15),
                onPressed: () => _logout(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final user = userList[index];
                    // Decode the Base64 image
                    final decodedImage = base64Decode(user.image);
                    // Create an Image widget from the decoded image data
                    final imageWidget =
                        Image.memory(decodedImage, width: 100, height: 100);
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xff6A5BF2), // Border color
                            width: 1.0, // Border width
                          ),
                          borderRadius:
                              BorderRadius.circular(4.0), // Border radius
                        ),
                        child: ListTile(
                          leading: imageWidget,
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserDetailScreen(user: user),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
