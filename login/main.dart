import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

String _getCookie(List<String>? cookies) {
  if (cookies != null && cookies.isNotEmpty) {
    final cookie = cookies.firstWhere(
      (cookie) => cookie.startsWith('jwt='),
      orElse: () => '',
    );
    return cookie.replaceFirst('jwt=', '');;
  }
  return '';
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyLoginPage(title: 'Login Page'),
    );
  }
}

class MyLoginPage extends StatefulWidget {
  const MyLoginPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    //Verifica si ambos campos del formulario han sido llenados. De lo contrario no intenta hacer el login
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text;
      final password = _passwordController.text;

      final url = Uri.parse('http://10.0.2.2:8080/login');
      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({
        'username': email,
        'password': password,
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON response and retrieve cookie
        final jsonResponse = jsonDecode(response.body);

        final cookies = response.headers['set-cookie']?.split(';');
        final cookie = _getCookie(cookies);

        print("--------------------- CHECK 4");

        setState(() {
          _isLoading = false;
        });

        if (cookie.isNotEmpty) {
          // Navigate to the verified page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VerifiedPage(title: 'Verified Page', cookie: cookie),
            ),
          );
        }
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        setState(() {
          _isLoading = false;
        });

        // Show the snackbar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales de inicio de sesión incorrectas'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor digite un email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor digite su contraseña';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : _login, //solo intenta hacer login si no está cargando un intento previo
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          'Iniciar sesión'), //si está cargando mostrar circularprogressindicator
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifiedPage extends StatelessWidget {
  const VerifiedPage({Key? key, required this.title, required this.cookie})
      : super(key: key);

  final String title;
  final String cookie;

  void _logout(BuildContext context) async {
    print(cookie);
    final url = Uri.parse('http://10.0.2.2:8080/logout');
    final headers = {
      "Authorization": "Bearer ${cookie}",
    };
    final response = await http.get(
      url,
      headers: headers,
    );
    if (response.statusCode == 200) {
      // Navigate to the login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyLoginPage(title: 'Login Page'),
        ),
      );
    } else {
      // Show the snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cerrar la sesión'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Ha iniciado sesión'),
            ),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
