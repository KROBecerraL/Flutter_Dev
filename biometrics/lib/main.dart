import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ProcessSignal.sigint.watch().listen((signal) async {
    // Clear the user token in the shared preferences
    await MySharedPreferences.clearToken();
    exit(0);
  });
  runApp(const MyApp());
}

void _logout(BuildContext context) async {
  final String? token = await MySharedPreferences.getToken();
  print(token);
  final url = Uri.parse('http://192.168.1.42:8080/logout');
  final headers = {
    "Authorization": "Bearer ${token}",
  };
  final response = await http.get(
    url,
    headers: headers,
  );
  if (response.statusCode == 200) {
    // Navigate to the login page
    MySharedPreferences.clearToken();
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyLoginPage(title: 'Login Page'),
      ),
    );
  }
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

class _MyLoginPageState extends State<MyLoginPage> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkLogin(BuildContext context) async {
    await MySharedPreferences.clearToken();
    /*
    String? token = await MySharedPreferences.getToken();
    if (token != '') {
      final url = Uri.parse('http://192.168.1.42:8080/protected');
      final headers = {'Authorization': 'Bearer ${token}'};

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then navigate to the verified page

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifiedPage(
              title: 'Verified Page',
            ),
          ),
        );
      }
    }
    */
  }

  Future<void> _authenticateUser(BuildContext context) async {
    final LocalAuthentication localAuth = LocalAuthentication();

    // check if the device has biometrics enabled
    bool hasBiometrics = await localAuth.canCheckBiometrics;

    // check which type of biometrics is available
    List<BiometricType> availableBiometrics =
        await localAuth.getAvailableBiometrics();

    if (hasBiometrics && availableBiometrics.isNotEmpty) {
      try {
        // request authentication from the user
        bool authenticated = await localAuth.authenticate(
          localizedReason: 'Autenticación requerida',
        );

        if (authenticated) {
          String? printToken = await FlutterFutureStorage.read(key: 'token');
          print("Trying to authenticate with token ${printToken}");

          final url = Uri.parse('http://192.168.1.42:8080/authtoken');
          final headers = {'Content-Type': 'application/json'};
          final body = json.encode({
            'printToken': printToken,
          });

          final response = await http.post(
            url,
            headers: headers,
            body: body,
          );

          if (response.statusCode == 200) {
            // If the server did return a 200 OK response,
            // then parse the JSON response and retrieve token
            final jsonResponse = jsonDecode(response.body);
            MySharedPreferences.saveToken(jsonResponse["token"]);

            setState(() {
              _isLoading = false;
            });
            if (MySharedPreferences.getToken() != "") {
              // Navigate to the verified page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VerifiedPage(
                    title: 'Verified Page',
                  ),
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
                content: Text(
                    'Lo sentimos, hubo un error al conectar con el servidor. Por favor intentelo nuevamente.'),
              ),
            );
          }
        }
      } catch (e) {
        // handle any exceptions from the local_auth package
        print(e);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Este dispositivo no cuenta con ningún método de identificación biometrica.'),
        ),
      );
    }
  }

  Future<Widget> _showAuthenticateWithBiometricsButton(
      BuildContext context) async {
    String? fingerprintLogin = await FlutterFutureStorage.read(key: 'token');
    if (fingerprintLogin != null) {
      print('token ${fingerprintLogin}');
      return ElevatedButton(
        onPressed: () async {
          await _authenticateUser(context);
        },
        child: const Text('Iniciar con datos biométricos'),
      );
    }
    // return an empty Container when the method returns null
    return Container();
  }

  void _login() async {
    //Verifica si ambos campos del formulario han sido llenados. De lo contrario no intenta hacer el login
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final email = _emailController.text;
      final password = _passwordController.text;

      final url = Uri.parse('http://192.168.1.42:8080/login');
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
        // then parse the JSON response and retrieve token
        final jsonResponse = jsonDecode(response.body);
        MySharedPreferences.saveToken(jsonResponse["token"]);

        setState(() {
          _isLoading = false;
        });

        if (MySharedPreferences.getToken() != "") {
          // Navigate to the verified page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifiedPage(
                title: 'Verified Page',
              ),
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
    _checkLogin(context);
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      print("Cerrar app");
      MySharedPreferences.clearToken();
    }
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
              FutureBuilder<Widget>(
                future: _showAuthenticateWithBiometricsButton(context),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VerifiedPage extends StatefulWidget {
  const VerifiedPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  _VerifiedPageState createState() => _VerifiedPageState();
}

class _VerifiedPageState extends State<VerifiedPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isBiometricsEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkStorage();
  }

  Future<void> _checkStorage() async {
    String? token = await FlutterFutureStorage.read(key: 'token');
    if (token != null) {
      setState(() {
        _isBiometricsEnabled = true;
      });
    } else {
      setState(() {
        _isBiometricsEnabled = false;
      });
    }
  }

  Future<void> _authenticateFingerprint(BuildContext context) async {
    final LocalAuthentication localAuth = LocalAuthentication();

    // check if the device has biometrics enabled
    bool hasBiometrics = await localAuth.canCheckBiometrics;

    // check which type of biometrics is available
    List<BiometricType> availableBiometrics =
        await localAuth.getAvailableBiometrics();

    if (hasBiometrics && availableBiometrics.isNotEmpty) {
      try {
        // request authentication from the user
        bool authenticated = await localAuth.authenticate(
            localizedReason: 'Autenticación requerida');

        if (authenticated) {
          // Show a modal bottom sheet asking for email and password
          // ignore: use_build_context_synchronously
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // make the sheet scrollable
            builder: (BuildContext context) {
              return SingleChildScrollView(
                // wrap the form in a SingleChildScrollView
                child: Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context)
                          .viewInsets
                          .bottom), // adjust the size of the container
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text('Confirmar inicio de sesión con huella.'),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Por favor digite su correo';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Por favor digite su contraseña';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // Confirmar las credenciales usuario/clave, si es correcto habilitar, de lo contrario no
                                final email = _emailController.text;
                                final password = _passwordController.text;
                                String? token =
                                    await MySharedPreferences.getToken();
                                print(token);

                                final url = Uri.parse(
                                    'http://192.168.1.42:8080/confirmcreds');
                                final headers = {
                                  'Authorization': 'Bearer ${token}',
                                  'Content-Type': 'application/json',
                                };
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
                                  // Si el servidor confirmó las credenciales, habilitar
                                  print('Aprobado, token de huella:');

                                  final jsonResponse =
                                      jsonDecode(response.body);
                                  print("response: " +
                                      jsonResponse["printToken"]);
                                  await FlutterFutureStorage.write(
                                      key: 'token',
                                      value: jsonResponse["printToken"]);
                                  setState(() {
                                    _isBiometricsEnabled = true;
                                    Navigator.pop(context);
                                  });
                                } else {
                                  // ERROR
                                  _emailController.clear();
                                  _passwordController.clear();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Credenciales incorrectas.'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text('Confirmar'),
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
      } catch (e) {
        // handle any exceptions from the local_auth package
        print(e);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Este dispositivo no cuenta con ningún método de identificación biométrica.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Text(
                _isBiometricsEnabled
                    ? 'Inicio de sesión con huella habilitado'
                    : 'Habilitar inicio de sesión con huella',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_isBiometricsEnabled == false) {
                  await _authenticateFingerprint(context);
                } else {
                  final LocalAuthentication localAuth = LocalAuthentication();

                  // check if the device has biometrics enabled
                  bool hasBiometrics = await localAuth.canCheckBiometrics;

                  // check which type of biometrics is available
                  List<BiometricType> availableBiometrics =
                      await localAuth.getAvailableBiometrics();

                  if (hasBiometrics && availableBiometrics.isNotEmpty) {
                    try {
                      // request authentication from the user
                      bool authenticated = await localAuth.authenticate(
                          localizedReason:
                              'Deshabilitar inicio de sesión con huella');

                      if (authenticated) {
                        String? printToken =
                            await FlutterFutureStorage.read(key: 'token');
                        String? token = await MySharedPreferences.getToken();

                        print("attempting to delete ${printToken}");
                        print("session token ${token}");

                        final url =
                            Uri.parse('http://192.168.1.42:8080/disableprint');
                        final headers = {
                          'Authorization': 'Bearer ${token}',
                          'Content-Type': 'application/json',
                        };
                        final body = json.encode({
                          'printToken': printToken,
                        });

                        final response = await http.post(
                          url,
                          headers: headers,
                          body: body,
                        );

                        if (response.statusCode == 200) {
                          // Si el servidor confirmó las credenciales, habilitar
                          print('Aprobado, token de huella:');
                          final jsonResponse = jsonDecode(response.body);
                          print("response: " + jsonResponse["printToken"]);
                          await FlutterFutureStorage.delete(key: 'token');
                          setState(() {
                            _isBiometricsEnabled = false;
                          });
                        } else {
                          // ERROR
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Credenciales incorrectas.'),
                            ),
                          );
                        }
                        await FlutterFutureStorage.delete(key: 'token');
                        setState(() {
                          _isBiometricsEnabled = false;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Huella invalida.'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error.'),
                        ),
                      );
                      print(e);
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                primary: _isBiometricsEnabled ? Colors.orange : Colors.green,
              ),
              child: Text(
                _isBiometricsEnabled ? 'Deshabilitar' : 'Habilitar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                primary: Colors.green,
              ),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
