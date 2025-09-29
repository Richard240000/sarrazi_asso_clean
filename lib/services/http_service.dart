import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/main.dart';

class HttpService {
  static String baseUrl = "https://www.association-sarrazi.fr";
  static Future<Tuple?> authentification(String email, String password) async {
    try {
      var route = "$baseUrl/verifier_login.php";
      var body = jsonEncode({'email': email.trim(), 'password': password.trim()});
      final response = await http.post(Uri.parse(route), headers: {'Content-Type': 'application/json'}, body: body);
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        await sharedPreferences.setString('email', data['email']);
        await sharedPreferences.setString('nom', data['nom']);
        return Tuple(true, null);
      } else {
        log(data['message']);
        return Tuple(false, data['message'] ?? 'Erreur de connexion');
      }
    } catch (e) {
      return Tuple(false, "Une erreur est survenue");
    }
  }
}

class Tuple<T> {
  Tuple(this.result, this.data);
  final bool result;
  final T data;
}
