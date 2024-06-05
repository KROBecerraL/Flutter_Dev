import 'package:flutter/material.dart';
import 'database.dart';

class AppState extends ChangeNotifier {
  late MyDatabase _userDatabase;

  MyDatabase get userDatabase => _userDatabase;

  Future<void> initialize() async {
    _userDatabase = MyDatabase();
    await _userDatabase.initializeDatabase();
  }

  void close() {
    _userDatabase.closeDatabase();
  }
}
