// lib/pages/ajouter_publication.dart
//
// Formulaire d'ajout d'un signalement -> POST publications_add.php
// - Récupère user_id depuis SharedPreferences (clé: 'user_id')
// - Validation simple
// - Retourne Navigator.pop(true) en cas de succès pour déclencher refresh
//
// Pré-requis pubspec.yaml :
//   http
//   shared_preferences

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AjouterPublicationPage extends StatefulWidget {
  const AjouterPublicationPage({super.key});

  @override
  State<AjouterPublicationPage> createState() => _AjouterPublicationPageState();
}

class _AjouterPublicationPageState extends State<AjouterPublicationPage> {
  static const String baseUrl = 'https://www.association-sarrazi.fr/';

  final _formKey = GlobalKey<FormState>();

  bool _submitting = false;
  int? _userId;

  static const String _type = 'signalement';

  String _urgence = 'normal'; // faible | normal | urgent

  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _secteurCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    _secteurCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('user_id');

    setState(() {
      _userId = uid;
    });

    if (uid == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            "Vous devez être connecté pour envoyer un signalement.",
          ),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            "Vous devez être connecté pour envoyer un signalement.",
          ),
        ),
      );
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final titre = _titreCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final categorie = _catCtrl.text.trim();
    final secteur = _secteurCtrl.text.trim();

    setState(() => _submitting = true);

    try {
      final uri = Uri.parse('${baseUrl}publications_add.php');

      final payload = <String, dynamic>{
        'user_id': _userId,
        'type': _type,
        'titre': titre,
        'description': description,
        'categorie': categorie,
        'secteur': secteur.isEmpty ? null : secteur,
        'urgence': _urgence,
      };

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(payload),
      );

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode} sur publications_add.php');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map || decoded['success'] != true) {
        final err = (decoded is Map)
            ? (decoded['error']?.toString() ?? 'Erreur ajout')
            : 'Réponse JSON invalide';
        throw Exception(err);
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Signalement envoyé'),
          content: const Text(
            "Votre signalement a bien été enregistré. Il sera visible dans l'application après validation.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Ajouter un signalement',
      body: (_userId == null)
          ? const Center(child: Text("Connexion requise."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildUrgenceSelector(),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _titreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        hintText: 'Ex : Lampadaire en panne',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 120,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Titre obligatoire';
                        if (s.length > 120) return 'Max 120 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _catCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie (optionnel)',
                        hintText: 'Ex : Éclairage, Voirie, Sécurité…',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 50,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.length > 50) return 'Max 50 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _secteurCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Secteur (optionnel)',
                        hintText: 'Ex : Route de Sarrazi , Rue du Hameau …',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 80,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.length > 80) return 'Max 80 caractères';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Décrivez clairement le problème constaté…',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      minLines: 4,
                      maxLines: 8,
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Description obligatoire';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      "Signalement publié après validation",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 25,
                            ),
                      label: Text(
                        _submitting ? 'Envoi...' : 'Envoyer le signalement',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(
                          EdgeInsetsGeometry.all(10),
                        ),
                        elevation: WidgetStatePropertyAll(5),
                        backgroundColor: WidgetStatePropertyAll(
                          Colors.blue[800],
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUrgenceSelector() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Niveau d’urgence',
        border: OutlineInputBorder(),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          padding: EdgeInsets.symmetric(vertical: 2),
          isDense: true,
          value: _urgence,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'faible', child: Text('Faible')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
          ],
          onChanged: _submitting
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _urgence = value);
                },
        ),
      ),
    );
  }
}
