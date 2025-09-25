import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AjouterIdeePage extends StatefulWidget {
  final String auteurNom;
  final String auteurEmail;

  const AjouterIdeePage({super.key, required this.auteurNom, required this.auteurEmail});

  @override
  _AjouterIdeePageState createState() => _AjouterIdeePageState();
}

class _AjouterIdeePageState extends State<AjouterIdeePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titreController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool enCours = false;

  Future<void> envoyerIdee() async {
    final titre = titreController.text.trim();
    final description = descriptionController.text.trim();

    if (titre.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() {
      enCours = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.association-sarrazi.fr/ajouter_idee.php'),
        body: {
          'titre': titre,
          'description': description,
          'auteur_nom': widget.auteurNom,
          'auteur_email': widget.auteurEmail,
        },
      );

      print('[DEBUG] Réponse brute serveur : ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Idée ajoutée avec succès !')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Erreur inconnue')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur réseau : ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('[DEBUG] Exception : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de l\'idée')),
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
      appBar: AppBar(title: Text("Nouvelle idée")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titreController,
                decoration: InputDecoration(labelText: 'Titre'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: enCours ? null : envoyerIdee,
                child: enCours
                    ? CircularProgressIndicator()
                    : Text("Soumettre"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
