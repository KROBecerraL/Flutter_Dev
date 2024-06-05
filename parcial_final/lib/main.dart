import 'dart:io';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'user_list.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

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

//Si el usuario no ha cerrado su sesión y su token no ha expirado, redireccionar a WelcomeScreen
void _checkLogin(BuildContext context) async {
  final token = await MySharedPreferences.getToken();
  if (token != null) {
    final url = Uri.parse('http://192.168.1.42:8080/protected');
    final headers = {'Authorization': 'Bearer ${token}'};
    print(headers);

    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      // Si el servidor retornó 200 OK
      // Navigate to the homepage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(),
        ),
      );
    } else {
      // De lo contrario, throw exception
      // Mostrar snackbar con mensaje de error
      print("Expired JWT");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Messaging App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Account Login'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  bool _passwordVisible = false;

  TextEditingController _emailLoginController = TextEditingController();
  TextEditingController _passwordLoginController = TextEditingController();
  TextEditingController _emailSignupController = TextEditingController();
  TextEditingController _passwordSignupController = TextEditingController();
  TextEditingController _nameSignupController = TextEditingController();
  TextEditingController _phoneSignupController = TextEditingController();
  TextEditingController _jobSignupController = TextEditingController();

  String? encodedPhoto;

  Future<String?> pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return null;

      final imageTemp = File(image.path);

      // Read the image file as bytes
      final bytes = await imageTemp.readAsBytes();

      // Encode the bytes to Base64
      final base64Image = base64Encode(bytes);

      setState(() {
        encodedPhoto = base64Image;
      });

      print(base64Image);
      return base64Image;
    } catch (e) {
      print('Failed to pick image: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Call _checkLogin method here
    _checkLogin(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_loginFormKey.currentState!.validate()) {
      // Si ambos campos se han llenado, hacer el login
      print('Email: ${_emailLoginController.text}');
      print('Password: ${_passwordLoginController.text}');

      final email = _emailLoginController.text;
      final password = _passwordLoginController.text;

      final url = Uri.parse('http://192.168.1.42:8080/login');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'email': email,
        'password': password,
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Si el servidor retornó 200 OK
        final jsonResponse = jsonDecode(response.body);
        await MySharedPreferences.saveToken(jsonResponse["token"]);
        String? tk = await MySharedPreferences.getToken();
        print('JWT ${tk}');

        final fcmToken = await FirebaseMessaging.instance.getToken();
        print("FCM Token: ${fcmToken}");

        //Check if fcm token is already in the DB, if it's not, add it
        final url = Uri.parse('http://192.168.1.42:8080/fcm-token');
        final headers = {'Content-Type': 'application/json'};
        final body = json.encode({
          'email': email,
          'fToken': fcmToken,
        });

        final responseFcm = await http.post(
          url,
          headers: headers,
          body: body,
        );

        print(responseFcm.body);

        setState(() {
          if (MySharedPreferences.getToken() != "") {
            // Navigate to the homepage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => WelcomeScreen(),
              ),
            );
          }
        });
      } else {
        // De lo contrario, throw exception
        setState(() {
          // Mostrar snackbar con mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect login credentials'),
            ),
          );
        });
      }
    }
  }

  void _signup() async {
    if (_signupFormKey.currentState!.validate()) {
      if (encodedPhoto != null) {
        // Realizar el registro
        print('Email: ${_emailSignupController.text}');
        print('Password: ${_passwordSignupController.text}');
        print('Name: ${_nameSignupController.text}');
        print('Phone number: ${_phoneSignupController.text}');
        print('Job: ${_jobSignupController.text}');
        print('Imagen:  ${encodedPhoto}');

        final email = _emailSignupController.text;
        final password = _passwordSignupController.text;
        final name = _nameSignupController.text;
        final phone = _phoneSignupController.text;
        final job = _jobSignupController.text;

        final url = Uri.parse('http://192.168.1.42:8080/register');
        final headers = {'Content-Type': 'application/json'};
        final body = json.encode({
          'email': email,
          'password': password,
          'image': encodedPhoto,
          'name': name,
          'phone': phone,
          'job': job
        });

        final response = await http.post(
          url,
          headers: headers,
          body: body,
        );

        if (response.statusCode == 201) {
          // Si el servidor retornó 201 OK
          setState(() {
            //Vaciar los campos de registro
            _nameSignupController.text = "";
            _phoneSignupController.text = "";
            _emailSignupController.text = "";
            _passwordSignupController.text = "";
            _jobSignupController.text = "";
            encodedPhoto = null;
          });
          //Mostrar un mensaje de registro exitoso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('The account was created successfully.'),
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'x',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          final jsonResponse = jsonDecode(response.body);
          await MySharedPreferences.saveToken(jsonResponse["token"]);
          String? tk = await MySharedPreferences.getToken();
          print('JWT ${tk}');

          //Guardar token FCM
          final fcmToken = await FirebaseMessaging.instance.getToken();
          print("FCM Token: ${fcmToken}");

          //Check if FCM token is already in the DB, if it's not, add it
          final url = Uri.parse('http://192.168.1.42:8080/fcm-token');
          final headers = {'Content-Type': 'application/json'};
          final body = json.encode({
            'email': email,
            'fToken': fcmToken,
          });

          final responseFcm = await http.post(
            url,
            headers: headers,
            body: body,
          );

          print(responseFcm.body);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(title: 'Messaging App'),
            ),
          );
        } else {
          // De lo contrario, throw exception
          setState(() {
            // Mostrar snackbar con mensaje de error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Please double check all fields and try uploading a smaller image.'),
                duration: Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'x',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must upload a photo, please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(150),
        child: Container(
          height: 150,
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
          child: TabBar(
            indicatorColor: Color(0xFF5AAC69),
            indicatorWeight: 2,
            controller: _tabController,
            tabs: [
              Tab(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Form(
            key: _loginFormKey,
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 50.0, horizontal: 40.0),
              children: [
                TextFormField(
                  controller: _emailLoginController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Input your email...',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please input your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordLoginController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Input your password...',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please input your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _login,
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF5AAC69),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(60.0),
                        ),
                        minimumSize: Size(150, 45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Form(
            key: _signupFormKey,
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 50.0, horizontal: 40.0),
              children: [
                TextFormField(
                  controller: _emailSignupController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Input your email...',
                    counterText: "",
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please input your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordSignupController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Input your password...',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please input your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _nameSignupController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Input your name...',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please input your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _phoneSignupController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    hintText: 'Input your phone number...',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please input your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _jobSignupController,
                  decoration: InputDecoration(
                    labelText: 'Job',
                    hintText: 'Input your job...',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please input your job';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                SizedBox(
                  child: ElevatedButton(
                    onPressed: () async {
                      await pickImage();
                    },
                    child: Text(
                      encodedPhoto != null ? 'Foto subida' : 'Subir una foto',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: encodedPhoto != null
                          ? Color(0xff6A5BF2)
                          : Colors.orange,
                    ),
                  ),
                ),
                SizedBox(height: 30.0),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 90),
                  child: ElevatedButton(
                    onPressed: _signup,
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold, // set the font weight to bold
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFF5AAC69),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(60.0),
                      ),
                      minimumSize: Size(double.infinity, 45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
