import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:sarrazi_asso_clean/main.dart';

class HttpService {
  static String baseUrl = "https://www.association-sarrazi.fr";
  static String authentification = "verifier_login.php";

  static Future<Tuple> verifieAuthentification(String email, String password) async {
    try {
      var route = "$baseUrl/verifier_login.php";
      log("**************************************************************");
      log(route);
      var body = jsonEncode({'email': email.trim(), 'password': password.trim()});

      // Vérifie la connexion internet
      final bool isConnected = await InternetConnection().hasInternetAccess;
      if (!isConnected) {
        log("=> pas de connexion internet");
        return Tuple(false, "Problème réseau.\nVeuillez vérifier votre connexion internet.");
      }

      final response = await http.post(Uri.parse(route), headers: {'Content-Type': 'application/json'}, body: body);
      log("[${response.statusCode}] ${response.body}");
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

  static Future<Tuple> chargerAnnonces() async {
    return await get("liste_annonces.php");
  }

  static Future<Tuple> chargerDocuments() async {
    return await get("get_documents.php");
  }

  static Future<Tuple> rechercheAnnuaire(String query) async {
    return await get("recherche_annuaire.php", query: "search=$query");
  }

  static Future<Tuple> chargerAgenda() async {
    return await get("get_evenements.php");
  }

  static Future<Tuple> chargerActualites() async {
    return await get("news.php");
  }

  static Future<Tuple> chargerArtisans() async {
    return await get("liste_artisans.php");
  }

  static Future<Tuple> get(String endpoint, {String? query}) async {
    try {
      var route = "$baseUrl/$endpoint";
      if (query?.isNotEmpty ?? false) {
        route += "?$query";
      }

      log("**************************************************************");
      log(route);

      // Vérifie la connexion internet
      final bool isConnected = await InternetConnection().hasInternetAccess;
      if (!isConnected) {
        log("=> pas de connexion internet");
        return Tuple(false, "Problème réseau.\nVeuillez vérifier votre connexion internet.");
      }

      // Si internet OK, envoi de la requête au serveur
      final response = await http.get(Uri.parse(route));
      log("[${response.statusCode}] ${response.body}");
      // Si requête OK, formate  la reponse et retourne les données à la page
      if (response.statusCode == 200) {
        return Tuple(true, json.decode(response.body));
      }
      // Si requête KO, retourne un message d'erreur à la page
      else {
        return Tuple(false, "Erreur lors du chargement des données");
      }
    } on Exception catch (e) {
      log("!!! EXCEPTION : ${e.toString()}");
      return Tuple(false, "Erreur lors du chargement des données");
    }
  }
}

class Tuple<T> {
  Tuple(this.isSuccess, this.data);
  final bool isSuccess;
  final T data;
}
