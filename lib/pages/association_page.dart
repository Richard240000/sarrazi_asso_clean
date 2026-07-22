import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';

class AssociationPage extends StatefulWidget {
  const AssociationPage({super.key});

  @override
  State<AssociationPage> createState() => _AssociationPageState();
}

class _AssociationPageState extends State<AssociationPage> {
  static const String apiUrl =
      "https://www.association-sarrazi.fr/get_association.php";

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
      final res = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) {
        setState(() {
          _error = "Erreur serveur (HTTP ${res.statusCode}).";
          _loading = false;
        });
        return;
      }

      final Map<String, dynamic> jsonMap = json.decode(
        utf8.decode(res.bodyBytes),
      );

      if (jsonMap["success"] != true) {
        setState(() {
          _error =
              jsonMap["error"]?.toString() ?? "Erreur inconnue côté serveur.";
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

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: "mailto",
      path: _contactEmail,
      query: "subject=${Uri.encodeComponent("Contact Association Sarrazi")}",
    );

    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Impossible d’ouvrir l’application mail."),
        ),
      );
    }
  }

  Widget _sectionCard({
    required String title,
    required String content,
    Widget? contentWidget,
    IconData? icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.blue[800]),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            contentWidget ??
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.isEmpty ? "Membre du bureau" : role,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "$prenom $nom".trim().isEmpty ? "—" : "$prenom $nom".trim(),
                  style: const TextStyle(fontSize: 15),
                ),
                if (tel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Téléphone : $tel",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final assoc = _association;
    final lieuDit = assoc?["lieu_dit"]?.toString() ?? "";
    final objet = assoc?["objet"]?.toString() ?? "";
    final associationTxt = assoc?["association"]?.toString() ?? "";
    final updatedAt = DateFormat("dd/MM/yyyy à HH:mm").format(
      DateTime.tryParse(assoc?["updated_at"]?.toString() ?? "") ??
          DateTime.now(),
    );

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
          ElevatedButton.icon(
            onPressed: _sendEmail,
            icon: const Icon(Icons.mail_outline, color: Colors.white, size: 25),
            label: const Text(
              "Nous écrire",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            style: ButtonStyle(
              elevation: WidgetStatePropertyAll(5),
              backgroundColor: WidgetStatePropertyAll(Colors.blue[800]),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: SizedBox(
              height: 400,
              child: FlutterMap(
                options: MapOptions(
                  keepAlive: true,
                  initialCenter: LatLng(45.170355, 0.674726),
                  initialZoom: 14,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),

                children: [
                  TileLayer(
                    userAgentPackageName: "com.sarrazi.app",
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    retinaMode: true,
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(45.170355, 0.674726),
                        radius: 600,
                        color: Colors.indigo.withAlpha(60),
                        useRadiusInMeter: true,
                      ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentGeometry.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 0),
                      child: InkWell(
                        child: Text(
                          ' © OpenStreetMap contributors ',
                          style: TextStyle(color: Colors.black38),
                        ),
                        onTap: () => launchUrl(
                          Uri.parse('https://openstreetmap.org/copyright'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          _sectionCard(title: "Lieu-dit", content: lieuDit, icon: Icons.place),
          _sectionCard(title: "Objet", content: objet, icon: Icons.flag),
          _sectionCard(
            title: "L’association",
            content: associationTxt,
            icon: Icons.groups,
          ),
          if (_bureau.isEmpty)
            _sectionCard(
              title: "Bureau",
              content: 'Aucun membre du bureau enregistré pour le moment',
              icon: Icons.apartment,
            )
          else
            _sectionCard(
              title: "Bureau",
              content: '',
              contentWidget: Column(
                children: [
                  ..._bureau.map(
                    (e) => _bureauCard((e as Map).cast<String, dynamic>()),
                  ),
                ],
              ),
              icon: Icons.apartment,
            ),

          if (updatedAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                "Mise à jour : $updatedAt",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: "L’Association", body: _buildBody());
  }
}
