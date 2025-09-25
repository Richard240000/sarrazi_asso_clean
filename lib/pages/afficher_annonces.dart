import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'ajouter_annonce.dart';

class AfficherAnnoncesPage extends StatefulWidget {
  const AfficherAnnoncesPage({super.key});

  @override
  _AfficherAnnoncesPageState createState() => _AfficherAnnoncesPageState();
}

class _AfficherAnnoncesPageState extends State<AfficherAnnoncesPage> {
  List annonces = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    chargerAnnonces();
  }

  Future<void> chargerAnnonces() async {
    final response = await http.get(
      Uri.parse('https://www.association-sarrazi.fr/liste_annonces.php'),
    );

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

  Future<void> _ajouterAnnonce() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AjouterAnnoncePage()),
    );
    if (result == true) chargerAnnonces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : annonces.isEmpty
                    ? Center(child: Text('Aucune annonce pour le moment.'))
                    : RefreshIndicator(
                        onRefresh: chargerAnnonces,
                        child: ListView.builder(
                          itemCount: annonces.length,
                          itemBuilder: (context, index) {
                            final a = annonces[index];
                            final date = DateTime.parse(a['date_publication']);
                            final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(date);

                            return Card(
                              margin: EdgeInsets.all(10),
                              child: Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a['titre'] ?? '', 
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    SizedBox(height: 5),
                                    Text(a['description'] ?? ''),
                                    if ((a['photo'] ?? '').isNotEmpty)
                                      Image.network(
                                        'https://www.association-sarrazi.fr/uploads_annonces/${a['photo']}',
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterAnnonce,
        tooltip: 'Ajouter une annonce',
        child: Icon(Icons.add),
      ),
    );
  }
}