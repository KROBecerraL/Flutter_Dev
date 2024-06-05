import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Show Modal Test',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _groupValue = '';
  String? _selectedColor;
  bool saved = false;

  void _showModalBottomSheet() {
    saved = false;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return Container(
            height: 200,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      _myRadioButton(
                        title: "Amarillo",
                        value: 'Amarillo',
                        onChanged: (newValue) {
                          setState(() {
                            _groupValue = newValue!;
                            print(_selectedColor);
                          });
                        },
                      ),
                      _myRadioButton(
                        title: "Azul",
                        value: 'Azul',
                        onChanged: (newValue) {
                          setState(() {
                            _groupValue = newValue!;
                            print(_selectedColor);
                          });
                        },
                      ),
                      _myRadioButton(
                        title: "Rojo",
                        value: 'Rojo',
                        onChanged: (newValue) {
                          setState(() {
                            _groupValue = newValue!;
                            print(_selectedColor);
                          });
                        },
                      ),
                      _myRadioButton(
                        title: "Verde",
                        value: 'Verde',
                        onChanged: (newValue) {
                          setState(() {
                            _groupValue = newValue!;
                            print(_selectedColor);
                          });
                        },
                      ),
                      _myRadioButton(
                        title: "Naranja",
                        value: 'Naranja',
                        onChanged: (newValue) {
                          setState(() {
                            _groupValue = newValue!;
                            print(_selectedColor);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _selectedColor = _groupValue;
                    saved = true;
                    Navigator.pop(context,
                        true); // Pass true to indicate the modal was closed
                  },
                  child: Text('Aceptar'),
                ),
              ],
            ),
          );
        });
      },
    ).then((value) {
      if (value != null && value == true) {
        setState(() {}); // Rebuild the widget tree and update the UI
      }
      if (saved == false) {
        _groupValue = _selectedColor!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ModalBottom demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showModalBottomSheet,
              child: Text('Mostrar opciones'),
            ),
            SizedBox(height: 16),
            Text(
              _selectedColor != null
                  ? 'Opción seleccionada: $_selectedColor'
                  : '',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _myRadioButton({
    required String title,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return RadioListTile(
      value: value,
      groupValue: _groupValue,
      onChanged: onChanged,
      title: Text(title),
    );
  }
}
