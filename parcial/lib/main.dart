import 'shared_preferences.dart';
import 'jwt.dart';
import 'package:flutter/material.dart';
import 'myWidget1.dart';
import 'myWidget2.dart';
import 'myWidget3.dart';
import 'myWidget4.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create an instance of AppState
  final appState = AppState();

  // Esperar a que inicie la instancia de la bd
  await appState.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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
  const MyLoginPage({super.key, required this.title});

  final String title;

  @override
  State<MyLoginPage> createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  //Se verifica que el usuario no haya iniciado sesión todavia. Si ya inicio sesión se redirecciona
  void verifyLogin() async {
    final isLoggedIn = await MySharedPreferences.getToken() != null;
    if (isLoggedIn) {
      // Redireccionar si ya ha iniciado sesión
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VerifiedPage(
            title: 'Artículos',
          ),
        ),
      );
      return;
    }
  }

  void _login() async {
    final userDatabase =
        Provider.of<AppState>(context, listen: false).userDatabase;

    //Verifica si ambos campos del formulario han sido llenados. De lo contrario no intenta hacer el login
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final username = _usernameController.text;
      final password = _passwordController.text;

      final userInfo = await userDatabase.getUserInfo(username, password);
      print(userInfo);

      //si las credenciales del usuario son correctas se genera el jwt y se guarda
      if (userInfo.isNotEmpty) {
        String userName = userInfo['username'];
        String userEmail = userInfo['email'];
        int userId = userInfo['UserID'];

        try {
          // ---------- GENERAR JWT USANDO EL ALGORITMO HMAC SHA-256 ----------
          await JWTGenerator().signToken(userId, userEmail, userName);
          // ---------- AUTENTICAR TOKEN ----------
          await JWTGenerator().authenticateToken();
          setState(() {
            _isLoading = false;
          });
          //Redireccionar usuario
          verifyLogin();
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          print("Error during login: $e");
        }
      } else {
        //si las credenciales de usuario no son correctas no se hace el login
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Credenciales de inicio de sesión incorrectas.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    verifyLogin();
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
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor digite un nombre de usuario';
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
                      ? CircularProgressIndicator()
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

class VerifiedPage extends StatefulWidget {
  const VerifiedPage({super.key, required this.title});

  final String title;

  @override
  _VerifiedPageState createState() => _VerifiedPageState();
}

class _VerifiedPageState extends State<VerifiedPage> {
  bool _isGridView =
      false; // flag para determinar si se muestra gridview o listview

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ],
            ),
            if (_isGridView) ArticuloGridView() else ArticuloListView(),
            ElevatedButton(
              onPressed: () {
                // Navigate to FavoritoListView on button press
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesPage(title: 'Artículos favoritos',),
                  ),
                );
              },
              child: const Text('Lista de favoritos'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userDatabase =
                    Provider.of<AppState>(context, listen: false).userDatabase;
                await userDatabase.deleteAllArticulosFavoritos();
                MySharedPreferences.clearToken();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyLoginPage(title: 'Login'),
                  ),
                );
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}


class _FavoritesPageState extends State<FavoritesPage> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.grid_view),
                  onPressed: () {
                    setState(() {
                      _isGridView = !_isGridView;
                    });
                  },
                ),
              ],
            ),
            if (_isGridView) FavoritoGridView() else FavoritoListView(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VerifiedPage(title: 'Artículos'),
                  ),
                );
              },
              child: const Text('Lista de artículos'),
            ),
            ElevatedButton(
              onPressed: () async {
                final userDatabase = Provider.of<AppState>(context, listen: false).userDatabase;
                MySharedPreferences.clearToken();
                await userDatabase.deleteAllArticulosFavoritos();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyLoginPage(title: 'Login'),
                  ),
                );
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}