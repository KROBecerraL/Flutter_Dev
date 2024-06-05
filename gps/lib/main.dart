import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'GPS'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<Position> obtenerGps() async {
    //Verificar si la ubicación del dispositivo está habilitada
    bool bGpsHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!bGpsHabilitado) {
      return Future.error('Por favor habilite el servicio de ubicación.');
    }
    //Validar permiso para utilizar los servicios de localización
    LocationPermission bGpsPermiso = await Geolocator.checkPermission();
    if (bGpsPermiso == LocationPermission.denied) {
      bGpsPermiso = await Geolocator.requestPermission();
      if (bGpsPermiso == LocationPermission.denied) {
        return Future.error('Se denegó el permiso para obtener la ubicación.');
      }
    }
    if (bGpsPermiso == LocationPermission.deniedForever) {
      return Future.error(
          'Se denegó el permiso para obtener la ubicación de forma permanente.');
    }
    //En este punto los permisos están habilitados y se puede consultar la ubicación
    return await Geolocator.getCurrentPosition();
  }

  Future<void> abrirUrl(final String sUrl) async {
    final Position coordActual = await obtenerGps();
    final Uri oUri = Uri.parse('$sUrl${coordActual.latitude},${coordActual.longitude}');;
    try {
      await launchUrl(
          oUri, //Ej: http://www.google.com/maps/place/6.2502089,-75.5706711
          mode: LaunchMode.externalApplication);
    } catch (oError) {
      return Future.error('No fue posible abrir la url: $sUrl.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => abrirUrl('http://www.google.com/maps/place/'),
              child: const Text('Obtener ubicación'),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
