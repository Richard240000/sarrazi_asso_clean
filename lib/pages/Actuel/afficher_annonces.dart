
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ajouter_annonce.dart';

class AfficherAnnoncesPage extends StatefulWidget {
  @override
  _AfficherAnnoncesPageState createState() => _AfficherAnnoncesPageState();
}

class _AfficherAnnoncesPageState extends State<AfficherAnnoncesPage> {
  List annonces = [];
  bool loading = true;
  String? utilisateur;

  @override
  void initState() {
    super.initState();
    chargerAnnonces();
    verifierConnexion();
  }

  Future<void> verifierConnexion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      utilisateur = prefs.getString('nom');
    });
  }

  Future<void> chargerAnnonces() async {
    final response = await http.get(
      Uri.parse('https://www.association-sarrazi.fr/liste_annonces.php'),
    );

    print('[DEBUG] Réponse JSON : ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        annonces = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Annonces Bons plans')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : annonces.isEmpty
              ? Center(child: Text('Aucune annonce-Bon plan pour le moment.'))
              : RefreshIndicator(
                  onRefresh: chargerAnnonces,
                  child: ListView.builder(
                    itemCount: annonces.length,
                    itemBuilder: (context, index) {
                      final a = annonces[index];
                      final date = DateTime.parse(a['date_publication']);
                      final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(date);

                      if ((a['photo'] ?? '').isNotEmpty) {
                        print('[DEBUG] Image URL : https://www.association-sarrazi.fr/uploads_annonces/${a['photo']}');
                      }

                      return Card(
                        margin: EdgeInsets.all(10),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['titre'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              SizedBox(height: 5),
                              Text(a['description'] ?? ''),
                              if ((a['photo'] ?? '').isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Image.network(
                                    'https://www.association-sarrazi.fr/uploads_annonces/${a['photo']}',
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('[ERREUR IMAGE] $error');
                                      return Container(
                                        color: Colors.red[100],
                                        padding: EdgeInsets.all(8),
                                        child: Text("Erreur image : $error"),
                                      );
                                    },
                                  ),
                                ),
                              SizedBox(height: 5),
                              Text(
                                "Publié par ${a['auteur_nom'] ?? 'Inconnu'} le $formattedDate",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: utilisateur != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AjouterAnnoncePage()),
                ).then((_) => chargerAnnonces());
              },
              child: Icon(Icons.add),
              tooltip: 'Ajouter une annonce',
            )
          : null,
    );
  }
}
