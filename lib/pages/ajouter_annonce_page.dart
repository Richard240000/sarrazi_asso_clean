import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/main.dart';

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

  @override
  void initState() {
    super.initState();

    // Recharge les infos auteur enregistrées au login
    nom = sharedPreferences.getString('nom');
    email = sharedPreferences.getString('email');
  }

  Future<void> _envoyerAnnonce() async {
    if (nom == null || email == null || nom!.isEmpty || email!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utilisateur non identifié.\nVeuillez vous reconnecter.")));
      return;
    }

    if (titreController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs')));
      return;
    }

    setState(() => loading = true);

    try {
      final uri = Uri.parse("https://www.association-sarrazi.fr/ajouter_annonce.php");
      final request = http.MultipartRequest('POST', uri);

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

      final response = await request.send().timeout(const Duration(seconds: 25));
      final respStr = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 200 && respStr.contains('"status":"success"')) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de l'envoi")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur réseau ou serveur")));
    } finally {
      if (mounted) setState(() => loading = false);
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
            decoration: const InputDecoration(labelText: 'Titre*'),
          ),
          const SizedBox(height: 20),
          TextField(
            textAlignVertical: TextAlignVertical.top,
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Description*'),
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: categorieController.text.isNotEmpty ? categorieController.text : null,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: ['Vente', 'Don', 'Service', 'Bon plan', 'Autre'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: (val) => categorieController.text = val ?? '',
          ),
          const SizedBox(height: 20),
          _image != null
              ? Column(
                  children: [
                    Image.file(_image!, height: 200),
                    TextButton(onPressed: () => setState(() => _image = null), child: const Text('Supprimer la photo')),
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
          const SizedBox(height: 8),
          const Text(
            "Annonce publiée après validation",
            style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: loading ? null : _envoyerAnnonce,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: loading ? const CircularProgressIndicator() : const Text('Publier l\'annonce'),
          ),
        ],
      ),
    );
  }
}
