import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/pages/ajouter_annonce_page.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';

import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';

class AnnoncesPages extends StatefulWidget {
  const AnnoncesPages({super.key});

  @override
  State<AnnoncesPages> createState() => _AnnoncesPagesState();
}

class _AnnoncesPagesState extends State<AnnoncesPages> {
  List annonces = [];
  bool loading = true;
  String? utilisateur;

  @override
  void initState() {
    super.initState();
    chargerAnnonces();
  }

  Future<void> chargerAnnonces() async {
    final response = await http.get(Uri.parse('https://www.association-sarrazi.fr/liste_annonces.php'));

    if (response.statusCode == 200) {
      setState(() {
        annonces = jsonDecode(response.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de chargement')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: "Annonces", body: getBody(), floatingButton: getFloatingButton());
  }

  Widget getBody() {
    return Column(
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
                              Text(a['titre'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              SizedBox(height: 5),
                              Text(a['description'] ?? ''),
                              if ((a['photo'] ?? '').isNotEmpty)
                                Image.network('https://www.association-sarrazi.fr/uploads_annonces/${a['photo']}', height: 200, width: double.infinity, fit: BoxFit.cover),
                              SizedBox(height: 5),
                              Text("Publié par ${a['auteur_nom'] ?? 'Inconnu'} le $formattedDate", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget? getFloatingButton() {
    return FloatingActionButton(
      onPressed: _ajouterAnnonce,
      tooltip: 'Ajouter une annonce',
      shape: const CircleBorder(),
      backgroundColor: Colors.blue[800],
      foregroundColor: Colors.white,
      child: Icon(Icons.add),
    );
  }

  Future<void> _ajouterAnnonce() async {
    if (sharedPreferences.getString('nom')?.isEmpty ?? true) {
      await showModalBottomSheet(context: context, builder: (context) => LoginBottomSheet(), isScrollControlled: true);
      setState(() {
        utilisateur = sharedPreferences.getString('nom');
      });
    }
    if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
      if (!context.mounted) return;
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AjouterAnnoncePage()));
      if (result == true) chargerAnnonces();
    }
  }
}
