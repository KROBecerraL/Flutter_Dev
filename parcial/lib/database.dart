import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class MyDatabase {
  static late Database _database;
  static final MyDatabase _singleton = MyDatabase._internal();

  factory MyDatabase() {
    return _singleton;
  }

  MyDatabase._internal();

  // ------------------------ IMPORTAR BASE DE DATOS -----------------------------
  Future<void> _copyDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = await rootBundle.load('assets/databases/sqlite.db');
    //VERIFICAR QUE LA BD TODAVÍA NO ESTE EN EL ALMACENAMIENTO LOCAL
    final bytes = dbFile.buffer.asUint8List(
      dbFile.offsetInBytes,
      dbFile.lengthInBytes,
    );
    await File('$dbPath/sqlite.db').writeAsBytes(bytes);
  }

  Future<void> _initDatabase() async {
    await _copyDatabase();
    final dbPath = await getDatabasesPath();
    _database = await openDatabase('$dbPath/sqlite.db');
  }
  // ------------------------------------------------------------------------------

  // ------------------------ COMANDOS PARA MODIFICAR BD EN APP -------------------
  Future<void> initializeDatabase() async {
    await _initDatabase();
  }

  static Database get database {
    return _database;
  }

  //login de usuario, si es exitoso return los datos del usuario
  Future<Map<String, dynamic>> getUserInfo(
      String username, String password) async {
    // Retrieve the user with the given username and password
    final user = await _database.rawQuery(
        'SELECT UserID, Username, Email FROM Usuarios WHERE Username = ? AND Password = ?',
        [username, password]);

    // Return the user's id, email and username, if found
    if (user.isNotEmpty) {
      return {
        'UserID': user[0]['UserID'],
        'username': user[0]['Username'],
        'email': user[0]['Email']
      };
    } else {
      return {};
    }
  }

  //agregar artículo a favoritos
  Future<void> addArticuloToFavoritos(int articleId, int userId) async {
    await _database.insert(
      'Articulos_favoritos',
      {'ArticleID': articleId, 'UserID': userId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    print(await _database.query('Articulos_favoritos'));
  }

  //quitar artículo de favoritos
  Future<void> removeArticuloFromFavoritos(int articleId, int userId) async {
    await _database.delete(
      'Articulos_favoritos',
      where: 'ArticleID = ? AND UserID = ?',
      whereArgs: [articleId, userId],
    );
    print(await _database.query('Articulos_favoritos'));
  }

  Future<List<Articulo>> getArticulosFavoritos(int userId) async {
    final List<Map<String, dynamic>> maps = await _database.rawQuery(
        'SELECT Articulos.* FROM Articulos_favoritos '
        'INNER JOIN Articulos ON Articulos.ArticleID = Articulos_favoritos.ArticleID '
        'WHERE Articulos_favoritos.UserID = ?',
        [userId]);

    return List.generate(maps.length, (i) {
      return Articulo.fromJson(maps[i]);
    });
  }

  // Método para eliminar todos los valores en la tabla Articulos_favoritos
  Future<void> deleteAllArticulosFavoritos() async {
    await _database.delete('Articulos_favoritos');
  }

  Future<void> closeDatabase() async {
    await _database.close();
  }
}

class Articulo {
  final int id;
  final String name;
  final String seller;
  final double rating;
  final String image;

  Articulo({
    required this.id,
    required this.name,
    required this.seller,
    required this.rating,
    required this.image,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      id: json['ArticleID'],
      name: json['Name'],
      seller: json['Seller'],
      rating: json['Rating'],
      image: json['Image'],
    );
  }

  int get articuloId => id;

  //Método para obtener todos los artículos, usado para mostrarlos en la app
  static Future<List<Articulo>> getArticulos() async {
    final List<Map<String, dynamic>> maps =
        await MyDatabase._database.query('Articulos');

    return List.generate(maps.length, (i) {
      return Articulo.fromJson(maps[i]);
    });
  }
}
