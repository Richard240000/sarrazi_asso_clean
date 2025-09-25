import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ajouter_idee.dart';
import 'ajouter_commentaire.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AfficherIdeesPage extends StatefulWidget {
  const AfficherIdeesPage({super.key});

  @override
  _AfficherIdeesPageState createState() => _AfficherIdeesPageState();
}

class _AfficherIdeesPageState extends State<AfficherIdeesPage> {
  List<dynamic> idees = [];
  String? utilisateurNom;

  @override
  void initState() {
    super.initState();
    chargerUtilisateur();
    chargerIdees();
  }

  Future<void> chargerUtilisateur() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      utilisateurNom = prefs.getString('nom') ?? '';
    });
  }

  Future<void> chargerIdees() async {
    final response = await http.get(
        Uri.parse('https://www.association-sarrazi.fr/liste_idees.php'));

    if (response.statusCode == 200) {
      setState(() {
        idees = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement des idées")),
      );
    }
  }

  void ouvrirAjoutIdee() async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString('nom');
    final email = prefs.getString('email');

    if (nom == null || email == null) {
      final success = await Navigator.pushNamed(context, '/login');
      if (success != true) return;
    }

    final nomApresLogin = prefs.getString('nom');
    final emailApresLogin = prefs.getString('email');

    if (nomApresLogin != null && emailApresLogin != null) {
      final resultat = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AjouterIdeePage(
            auteurNom: nomApresLogin,
            auteurEmail: emailApresLogin,
          ),
        ),
      );

      if (resultat == true) {
        chargerIdees();
      }
    }
  }

  void ouvrirAjoutCommentaire(int ideeId) async {
    final prefs = await SharedPreferences.getInstance();
    final nom = prefs.getString('nom');

    if (nom == null) {
      final success = await Navigator.pushNamed(context, '/login');
      if (success != true) return;
    }

    final nomApresLogin = prefs.getString('nom');

    if (nomApresLogin != null) {
      final resultat = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AjouterCommentairePage(
            ideeId: ideeId,
            auteurNom: nomApresLogin,
          ),
        ),
      );

      if (resultat == true) {
        chargerIdees();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Idées & Projets')),
      body: idees.isEmpty
          ? Center(child: Text("Aucune idée à partager pour l’instant."))
          : ListView.builder(
        itemCount: idees.length,
        itemBuilder: (context, index) {
          final idee = idees[index];
          final commentaires = idee['commentaires'] as List<dynamic>? ?? [];

          return Card(
            margin: EdgeInsets.all(10),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idee['titre'] ?? '',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(idee['description'] ?? ''),
                  SizedBox(height: 6),
                  Text("Par ${idee['auteur_nom'] ?? 'Anonyme'} le ${idee['date_publication'] ?? ''}",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  Divider(),
                  Text("Commentaires :", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...commentaires.map((commentaire) => ListTile(
                    title: Text(commentaire['commentaire'] ?? ''),
                    subtitle: Text("Par ${commentaire['auteur_nom'] ?? 'Anonyme'}"),
                  )),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => ouvrirAjoutCommentaire(idee['id']),
                      icon: Icon(Icons.add_comment),
                      label: Text("Commenter"),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ouvrirAjoutIdee,
        tooltip: "Proposer une idée",
        child: Icon(Icons.add),
      ),
    );
  }
}
