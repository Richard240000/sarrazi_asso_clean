import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AjouterCommentairePage extends StatefulWidget {
  final int ideeId;
  final String auteurNom;

  const AjouterCommentairePage({super.key, required this.ideeId, required this.auteurNom});

  @override
  _AjouterCommentairePageState createState() => _AjouterCommentairePageState();
}

class _AjouterCommentairePageState extends State<AjouterCommentairePage> {
  final TextEditingController texteController = TextEditingController();
  bool enCours = false;

  Future<void> envoyerCommentaire() async {
    final texte = texteController.text.trim();

    if (texte.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un commentaire')),
      );
      return;
    }

    setState(() {
      enCours = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.association-sarrazi.fr/ajouter_commentaire.php'),
        body: {
          'idee_id': widget.ideeId.toString(),
          'texte': texte,
          'auteur_nom': widget.auteurNom,
        },
      );

      print('[DEBUG] Réponse serveur : ${response.body}');
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Erreur inconnue')),
        );
      }
    } catch (e) {
      print('Erreur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du commentaire')),
      );
    } finally {
      setState(() {
        enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajouter un commentaire')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: texteController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Votre commentaire',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: enCours ? null : envoyerCommentaire,
              child: enCours
                  ? CircularProgressIndicator()
                  : Text("Envoyer"),
            ),
          ],
        ),
      ),
    );
  }
}
