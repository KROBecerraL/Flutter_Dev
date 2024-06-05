import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(
    const GetMaterialApp(
      home: VistaRuta1(title: 'Vista 1'),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto Rutas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const VistaRuta1(title: 'Vista 1'),
        '/vista2': (context) => const VistaRuta2(title: 'Vista 2'),
      },
    );
  }
}

class VistaRuta1 extends StatefulWidget {
  const VistaRuta1({super.key, required this.title});

  final String title;

  @override
  State<VistaRuta1> createState() => _VistaRuta1State();
}

class _VistaRuta1State extends State<VistaRuta1> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista 1'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Get.to(() => const VistaRuta2(title: 'Vista 2'));
              },
              child: const Text('Vista 2'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.to(() => const VistaRuta3(title: 'Vista 3'));
              },
              child: const Text('Vista 3'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => const VistaRuta4(title: 'Vista 4',)),
                );
              },
              child: const Text('Vista 4'),
            ),
          ],
        ),
      ),
    );
  }
}

class VistaRuta2 extends StatelessWidget {
  const VistaRuta2({super.key, required this.title});

  final String title;

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
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
              child: const Text('Vista 1'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.to(() => const VistaRuta3(title: 'Vista 3'));
              },
              child: const Text('Vista 3'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => const VistaRuta4(title: 'Vista 4',)),
                );
              },
              child: const Text('Vista 4'),
            ),
          ],
        ),
      ),
    );
  }
}

class VistaRuta3 extends StatelessWidget {
  const VistaRuta3({super.key, required this.title});

  final String title;

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
            ElevatedButton(
              onPressed: () {
                Get.to(() => const VistaRuta1(title: 'Vista 1'));
              },
              child: const Text('Vista 1'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.to(() => const VistaRuta2(title: 'Vista 2'));
              },
              child: const Text('Vista 2'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                MaterialPageRoute(builder: (context) => const VistaRuta4(title: 'Vista 4',)),
                );
              },
              child: const Text('Vista 4'),
            ),
          ],
        ),
      ),
    );
  }
}

class VistaRuta4 extends StatelessWidget {
  const VistaRuta4({super.key, required this.title});

  final String title;

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
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Volver a vista anterior'),
            ),
          ],
        ),
      ),
    );
  }
}
