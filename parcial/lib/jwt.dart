import 'dart:convert';
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'shared_preferences.dart';

class JWTGenerator {
  static late String token;
  static late String generatedSecret;

  //generar el secret random en el que "length" es el numero de caracteres
  String generateRandomSecret(int length) {
    var rand = Random.secure();
    var values = List<int>.generate(length, (i) => rand.nextInt(256));
    generatedSecret = base64Url.encode(values);
    return generatedSecret;
  }

  // ---------- GENERAR JWT USANDO EL ALGORITMO HMAC SHA-256 ----------

  Future<String> signToken(int uID, String userEmail, String userName) async {
    generatedSecret = generateRandomSecret(32);

    // Establecer que el JWT expira en 7 días
    final now = DateTime.now().toUtc();
    final expires = now.add(const Duration(days: 7));

    // Generar el JWT
    final jwt = JWT({
      'sub': uID.toString(),
      'email': userEmail,
      'name': userName,
      'exp': expires.millisecondsSinceEpoch ~/ 1000
    }, issuer: 'Carolina Becerra');

    // Firmarlo
    await MySharedPreferences.saveSecret(generatedSecret);
    final token = jwt.sign(SecretKey(generatedSecret));
    print('Token firmada: $token\n');
    await MySharedPreferences.saveToken(token);
    return token;
  }

  //------------------- VERIFICAR TOKEN -------------------
  Future<dynamic> authenticateToken() async {
    try {
      final checkToken = await MySharedPreferences.getToken();
      final checkSecret = await MySharedPreferences.getSecret();
      final jwt = await JWT.verify(checkToken!, SecretKey(checkSecret!));
      print('Token guardada: ${checkToken}');
      return jwt.payload['sub'];
    } on JWTExpiredError {
      print('El JWT expiró');
    } on JWTError catch (ex) {
      print(ex.message);
      // ex: Firma invalida
    }
  }
}
