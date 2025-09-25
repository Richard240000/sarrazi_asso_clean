import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AjouterAnnoncePage extends StatefulWidget {
  const AjouterAnnoncePage({super.key});

  @override
  _AjouterAnnoncePageState createState() => _AjouterAnnoncePageState();
}

class _AjouterAnnoncePageState extends State<AjouterAnnoncePage> {
  final titreController = TextEditingController();
  final descriptionController = TextEditingController();
  final categorieController = TextEditingController();
  File? _image;
  bool loading = false;
  String? nom;
  String? email;

  @override
  void initState() {
    super.initState();
    _chargerUtilisateur();
  }

  Future<void> _chargerUtilisateur() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nom = prefs.getString('nom');
      email = prefs.getString('email');
    });
  }

  Future<void> _envoyerAnnonce() async {
    if (titreController.text.isEmpty || descriptionController.text.isEmpty || nom == null || email == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Champs manquants ou utilisateur non identifié.')));
      return;
    }

    setState(() => loading = true);

    var uri = Uri.parse("https://www.association-sarrazi.fr/ajouter_annonce.php");
    var request = http.MultipartRequest('POST', uri);
    request.fields['titre'] = titreController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['categorie'] = categorieController.text;
    request.fields['auteur_nom'] = nom!;
    request.fields['auteur_email'] = email!;
    request.fields['visible'] = '1';

    if (_image != null) {
      final mimeType = lookupMimeType(_image!.path) ?? 'image/jpeg';
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        _image!.path,
        contentType: MediaType.parse(mimeType),
        filename: p.basename(_image!.path),
      ));
    }

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    print("[DEBUG] réponse serveur : $respStr");

    setState(() => loading = false);

    if (respStr.contains('success')) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'envoi.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Annonce-Bon plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: titreController, decoration: InputDecoration(labelText: 'Titre')),
            TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            DropdownButtonFormField<String>(
              value: categorieController.text.isNotEmpty ? categorieController.text : null,
              decoration: InputDecoration(labelText: 'Catégorie'),
              items: ['Vente', 'Don', 'Service', 'Bon plan', 'Autre'].map((cat) {
                return DropdownMenuItem<String>(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  categorieController.text = val ?? '';
                });
              },
            ),

            SizedBox(height: 10),
            _image != null
                ? Image.file(_image!, height: 150)
                : TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) setState(() => _image = File(picked.path));
                    },
                    icon: Icon(Icons.photo),
                    label: Text("Choisir une photo"),
                  ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _envoyerAnnonce,
              child: loading ? CircularProgressIndicator(color: Colors.white) : Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}
