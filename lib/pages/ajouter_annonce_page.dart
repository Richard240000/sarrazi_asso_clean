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

  final List<File> _images = [];
  bool loading = false;
  String? nom;
  String? email;

  static const int maxPhotos = 3;

  @override
  void initState() {
    super.initState();

    // Recharge les infos auteur enregistrées au login
    nom = sharedPreferences.getString('nom');
    email = sharedPreferences.getString('email');
  }

  Future<void> _choisirPhotos() async {
    final placesRestantes = maxPhotos - _images.length;

    if (placesRestantes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Maximum 3 photos par annonce'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isEmpty) return;

    final fichiersSelectionnes = pickedFiles.take(placesRestantes).map((xfile) => File(xfile.path)).toList();

    setState(() {
      _images.addAll(fichiersSelectionnes);
    });

    if (pickedFiles.length > placesRestantes && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Seules les 3 premières photos sont conservées'),
        ),
      );
    }
  }

  Future<void> _envoyerAnnonce() async {
    if (nom == null || email == null || nom!.isEmpty || email!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Utilisateur non identifié.\nVeuillez vous reconnecter."),
        ),
      );
      return;
    }

    if (titreController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Veuillez remplir tous les champs'),
        ),
      );
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

      for (final image in _images.take(maxPhotos)) {
        final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

        // Nouveau champ multiple attendu par ajouter_annonce.php
        request.files.add(
          await http.MultipartFile.fromPath(
            'photos[]',
            image.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send().timeout(const Duration(seconds: 25));
      final respStr = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 200 && respStr.contains('"status":"success"')) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text("Erreur lors de l'envoi"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Erreur réseau ou serveur"),
        ),
      );
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titreController,
            decoration: const InputDecoration(labelText: 'Titre*', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          TextField(
            textAlignVertical: TextAlignVertical.top,
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Description*', border: OutlineInputBorder()),
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: categorieController.text.isNotEmpty ? categorieController.text : null,
            decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder()),
            items: ['Vente', 'Don', 'Service', 'Bon plan', 'Autre'].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: (val) => categorieController.text = val ?? '',
          ),
          const SizedBox(height: 20),

          if (_images.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_images.length, (index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _images[index],
                        width: 95,
                        height: 95,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _images.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 12),
          ],

          TextButton.icon(
            onPressed: loading || _images.length >= maxPhotos ? null : _choisirPhotos,
            icon: Icon(Icons.photo_library, color: _images.length >= maxPhotos ? Colors.grey : Colors.blue[800]),
            label: Text(
              _images.isEmpty ? 'Ajouter jusqu’à 3 photos' : 'Ajouter une photo (${_images.length}/3)',
              style: TextStyle(color: _images.length >= maxPhotos ? Colors.grey : Colors.blue[800]),
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            "Annonce publiée après validation",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: loading ? null : _envoyerAnnonce,
            icon: const Icon(Icons.send, color: Colors.white, size: 25),
            label: Text(loading ? 'Envoi...' : 'Publier l\'annonce', style: const TextStyle(color: Colors.white, fontSize: 16)),
            style: ButtonStyle(
              padding: const WidgetStatePropertyAll(EdgeInsetsGeometry.all(10)),
              elevation: const WidgetStatePropertyAll(5),
              backgroundColor: WidgetStatePropertyAll(Colors.blue[800]),
              shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)))),
            ),
          ),
        ],
      ),
    );
  }
}
