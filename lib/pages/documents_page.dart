import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:sarrazi_asso_clean/services/popup_service.dart';
import 'package:share_plus/share_plus.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List documents = [];
  bool isLoading = true;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    chargerDocuments();
  }

  Future<void> chargerDocuments() async {
    setState(() => isLoading = true);

    final response = await HttpService.chargerDocuments();
    if (response.isSuccess) {
      setState(() {
        documents = response.data;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      PopupService.showErrorMessage(context, response.data?.toString());
      setState(() => isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)));
  }

  String _sanitizeFileName(String name) {
    final sanitized = name.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'document.pdf' : sanitized;
  }

  Future<Directory> _getPdfCacheDir() async {
    final base = await getApplicationSupportDirectory(); // Android + iOS
    final pdfDir = Directory('${base.path}/pdf');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  Future<String> _getLocalPdfPath({required String url, required String fileName}) async {
    final dir = await _getPdfCacheDir();
    final safeName = _sanitizeFileName(fileName);
    final path = '${dir.path}/$safeName';
    final file = File(path);

    if (await file.exists()) return path;

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    await file.writeAsBytes(response.bodyBytes);
    return path;
  }

  Future<void> lireDocument(String url, String titre) async {
    if (_busy) return;
    _busy = true;

    setState(() => isLoading = true);
    try {
      if (url.trim().isEmpty) {
        _snack("Lien du document manquant.");
        return;
      }

      final localPath = await _getLocalPdfPath(url: url, fileName: '$titre.pdf');

      final result = await OpenFile.open(localPath);

      if (!mounted) return;
      if (result.type != ResultType.done) {
        _snack("Impossible d'ouvrir le PDF. Installez un lecteur PDF si besoin.");
      }
    } catch (_) {
      if (!mounted) return;
      _snack("Erreur : impossible d'ouvrir le document.");
    } finally {
      if (mounted) setState(() => isLoading = false);
      _busy = false;
    }
  }

  Future<void> partagerDocument(String url, String titre) async {
    if (_busy) return;
    _busy = true;
    try {
      if (url.trim().isEmpty) {
        _snack("Lien du document manquant.");
        return;
      }

      final localPath = await _getLocalPdfPath(url: url, fileName: '$titre.pdf');
      await SharePlus.instance.share(ShareParams(sharePositionOrigin: Rect.fromLTWH(0, 0, 1, 1), files: [XFile(localPath)], title: titre));
    } on Exception catch (e) {
      if (!mounted) return;
      _snack("Erreur : impossible de partager le document.");
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: "Documents de l'association", body: _body());
  }

  Widget _body() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (documents.isEmpty) return const Center(child: Text('Aucun document disponible.'));

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];

        final String titre = (doc['titre'] ?? '').toString();
        final String url = (doc['url'] ?? '').toString();
        final DateTime date = DateTime.tryParse((doc['date_mise_en_ligne'] ?? '').toString()) ?? DateTime.now();

        return Card(
          child: ListTile(
            contentPadding: EdgeInsets.fromLTRB(10, 0, 15, 10),
            leading: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Icon(Icons.picture_as_pdf, color: Color(0xFFd50000), size: 30, weight: 600),
            ),
            titleAlignment: ListTileTitleAlignment.top,
            title: Text(titre, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Paru le ${DateFormat("dd/MM/yyyy à HH:mm").format(date)}", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                Row(
                  spacing: 15,
                  children: [
                    Spacer(),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(color: Color(0xFF00796B).withAlpha(200), shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(Icons.visibility_outlined, color: Colors.white, size: 20, weight: 700),
                        tooltip: 'Ouvrir',
                        onPressed: () => lireDocument(url, titre), // ✅ lecture rapide
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(color: Color(0xFF0277BD).withAlpha(200), shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(Icons.share_outlined, color: Colors.white, size: 20),
                        tooltip: 'Partager',
                        onPressed: () => partagerDocument(url, titre), // ✅ garder / envoyer
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => lireDocument(url, titre), // ✅ lecture rapide
          ),
        );
      },
    );
  }
}
