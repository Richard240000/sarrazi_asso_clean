import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';

class AssociationPage extends StatefulWidget {
  const AssociationPage({super.key});

  @override
  State<AssociationPage> createState() => _AssociationPageState();
}

class _AssociationPageState extends State<AssociationPage> {
  static const String apiUrl = "https://www.association-sarrazi.fr/get_association.php";

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _association;
  List<dynamic> _bureau = [];
  String _contactEmail = "contact@association-sarrazi.fr";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) {
        setState(() {
          _error = "Erreur serveur (HTTP ${res.statusCode}).";
          _loading = false;
        });
        return;
      }

      final Map<String, dynamic> jsonMap = json.decode(utf8.decode(res.bodyBytes));

      if (jsonMap["success"] != true) {
        setState(() {
          _error = jsonMap["error"]?.toString() ?? "Erreur inconnue côté serveur.";
          _loading = false;
        });
        return;
      }

      setState(() {
        _contactEmail = (jsonMap["contact_email"] ?? _contactEmail).toString();
        _association = (jsonMap["association"] as Map).cast<String, dynamic>();
        _bureau = (jsonMap["bureau"] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erreur réseau : $e";
        _loading = false;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d’ouvrir le lien.")),
      );
    }
  }

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: "mailto",
      path: _contactEmail,
      query: "subject=${Uri.encodeComponent("Contact Association Sarrazi")}",
    );

    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d’ouvrir l’application mail.")),
      );
    }
  }

  Widget _sectionCard({
    required String title,
    required String content,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content.isEmpty ? "—" : content,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bureauCard(Map<String, dynamic> m) {
    final role = (m["role"] ?? "").toString();
    final nom = (m["nom"] ?? "").toString();
    final prenom = (m["prenom"] ?? "").toString();
    final tel = (m["telephone"] ?? "").toString().trim();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.isEmpty ? "Membre du bureau" : role,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$prenom $nom".trim().isEmpty ? "—" : "$prenom $nom".trim(),
                    style: const TextStyle(fontSize: 15),
                  ),
                  if (tel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text("Téléphone : $tel", style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final assoc = _association;
    final lieuDit = assoc?["lieu_dit"]?.toString() ?? "";
    final objet = assoc?["objet"]?.toString() ?? "";
    final associationTxt = assoc?["association"]?.toString() ?? "";
    final mapsUrl = assoc?["google_maps_url"]?.toString().trim() ?? "";
    final updatedAt = assoc?["updated_at"]?.toString() ?? "";

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh),
                label: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _sendEmail,
                    icon: const Icon(Icons.mail),
                    label: const Text("Contacter"),
                  ),
                  if (mapsUrl.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _openUrl(mapsUrl),
                      icon: const Icon(Icons.map),
                      label: const Text("Google Maps"),
                    ),
                  OutlinedButton.icon(
                    onPressed: _fetchData,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Rafraîchir"),
                  ),
                ],
              ),
            ),
          ),

          if (updatedAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                "Mise à jour : $updatedAt",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),

          _sectionCard(
            title: "Lieu-dit",
            content: lieuDit,
            icon: Icons.place,
          ),
          _sectionCard(
            title: "Objet",
            content: objet,
            icon: Icons.flag,
          ),
          _sectionCard(
            title: "L’association",
            content: associationTxt,
            icon: Icons.groups,
          ),

          const SizedBox(height: 6),
          const Text(
            "Bureau",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          if (_bureau.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text("— Aucun membre du bureau enregistré pour le moment."),
            )
          else
            ..._bureau.map((e) => _bureauCard((e as Map).cast<String, dynamic>())).toList(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "L’Association",
      body: _buildBody(),
    );
  }
}