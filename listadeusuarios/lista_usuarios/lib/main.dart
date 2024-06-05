import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<List<User>> fetchUsers(http.Client client) async {
  final response =
      await client.get(Uri.parse('https://api.npoint.io/08243b2b78f7edb5ed59'));

  return compute(parseUsers, response.body);
}

//Convertir response a una Lista<User>.
List<User> parseUsers(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<User>((json) => User.fromJson(json)).toList();
}

class User {
  final String imagen;
  final String nombre;
  final String carrera;
  final double promedio;

  const User(
      {required this.imagen,
      required this.nombre,
      required this.carrera,
      required this.promedio});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      imagen: json['imagen'] as String,
      nombre: json['nombre'] as String,
      carrera: json['carrera'] as String,
      promedio: json['promedio'] as double,
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const appTitle = 'Lista de Usuarios';

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      home: UserList(title: appTitle),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<User>>(
          future: fetchUsers(http.Client()),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text("Error importando los datos."),
              );
            } else if (snapshot.hasData) {
              return UsersList(users: snapshot.data!);
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }
}

class UsersList extends StatelessWidget {
  const UsersList({super.key, required this.users});

  final List<User> users;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Image.asset('assets/images/' + users[index].imagen),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(users[index].nombre),
                      Text(users[index].carrera),
                      Text(users[index].promedio.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
