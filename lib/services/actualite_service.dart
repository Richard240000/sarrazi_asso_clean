import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/actualite.dart';

class ActualiteService {
  static const String _url = 'https://www.association-sarrazi.fr/news.php';

  Future<List<Actualite>> fetchActualites() async {
    try {
      final response = await http.get(Uri.parse(_url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        // Ajout d'un log pour debugger la structure des données reçues
        print('Données reçues: $jsonData');

        return jsonData.map((json) => Actualite.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des actualités - Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des actualités: $e');
      throw Exception('Erreur réseau: $e');
    }
  }
}
