import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';

class AjouterAnnoncePage extends StatefulWidget {
  const AjouterAnnoncePage({super.key});

  @override
  State<AjouterAnnoncePage> createState() => _AjouterAnnoncePageState();
}

class _AjouterAnnoncePageState extends State<AjouterAnnoncePage> {
  final titreController = TextEditingController();
  final descriptionController = TextEditingController();
  final categorieController = TextEditingController();
  File? _image;
  bool loading = false;
  String? nom;
  String? email;

  Future<void> _envoyerAnnonce() async {
    if (titreController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Veuillez remplir tous les champs')));
      return;
    }

    setState(() => loading = true);

    try {
      var uri = Uri.parse("https://www.association-sarrazi.fr/ajouter_annonce.php");
      var request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'titre': titreController.text,
        'description': descriptionController.text,
        'categorie': categorieController.text,
        'auteur_nom': nom!,
        'auteur_email': email!,
        'visible': '1',
      });

      if (_image != null) {
        final mimeType = lookupMimeType(_image!.path) ?? 'image/jpeg';
        request.files.add(await http.MultipartFile.fromPath('photo', _image!.path, contentType: MediaType.parse(mimeType)));
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (respStr.contains('success')) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'envoi")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de connexion')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: 'Nouvelle annonce', body: getBody(), isBottomBarVisible: false);
  }

  Widget getBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: titreController,
            decoration: InputDecoration(labelText: 'Titre*'),
          ),
          SizedBox(height: 20),
          TextField(
            textAlignVertical: TextAlignVertical.top,
            controller: descriptionController,
            decoration: InputDecoration(labelText: 'Description*'),
            maxLines: 4,
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: categorieController.text.isNotEmpty ? categorieController.text : null,
            decoration: InputDecoration(labelText: 'Catégorie'),
            items: ['Vente', 'Don', 'Service', 'Bon plan', 'Autre'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: (val) => categorieController.text = val ?? '',
          ),
          SizedBox(height: 20),
          _image != null
              ? Column(
                  children: [
                    Image.file(_image!, height: 200),
                    TextButton(onPressed: () => setState(() => _image = null), child: Text('Supprimer la photo')),
                  ],
                )
              : TextButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() => _image = File(picked.path));
                    }
                  },
                  icon: Icon(Icons.photo, color: Colors.blue[800]),
                  label: Text('Ajouter une photo', style: TextStyle(color: Colors.blue[800])),
                ),
          // ⭐⭐⭐ AJOUT DE L'AVERTISSEMENT ICI ⭐⭐⭐
          SizedBox(height: 8),
          Text(
            "Annonce publiée après validation",
            style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          // ⭐⭐⭐ FIN DE L'AJOUT ⭐⭐⭐
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: loading ? null : _envoyerAnnonce,
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
            child: loading ? CircularProgressIndicator() : Text('Publier l\'annonce'),
          ),
        ],
      ),
    );
  }
}
