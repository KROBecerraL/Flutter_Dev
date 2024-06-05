import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'photoViewer.dart';

/*
  Fuentes:
  https://docs.flutter.dev/cookbook/plugins/picture-using-camera
  https://medium.com/unitechie/flutter-tutorial-image-picker-from-camera-gallery-c27af5490b74
*/

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  File? image;
  Future<String?> pickImage() async {
    String? imagePath;
    try {
      print("Function executed");
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return null;
      final imageTemp = File(image.path);
      print("Image was selected");
      setState(() {
        this.image = imageTemp;
        imagePath = image.path;
      });
      return imagePath;
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<String?> captureImage() async {
    String? imagePath;
    try {
      print("Function executed");
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image == null) return null;
      final imageTemp = File(image.path);
      print("Image was selected");
      setState(() {
        this.image = imageTemp;
        imagePath = image.path;
      });
      print(imagePath);
      return imagePath;
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homepage',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Opciones',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Compartir imagen desde:',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: () async {
                    String? imagePath = await captureImage();
                    if (imagePath != null) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DisplayPictureScreen(
                            imagePath: imagePath,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Cámara',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.orange,
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: () async {
                    String? imagePath = await pickImage();
                    if (imagePath != null) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DisplayPictureScreen(
                            imagePath: imagePath,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Galería',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
