import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    chargerDocuments();
  }

  Future<void> chargerDocuments() async {
    setState(() {
      isLoading = true;
    });
    final response = await HttpService.chargerDocuments();
    if (response.isSuccess) {
      setState(() {
        documents = response.data;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      PopupService.showErrorMessage(context, response.data?.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> downloadAndShare(String url, String fileName) async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Directory dir;
        if (Platform.isAndroid) {
          dir = (await getExternalStorageDirectory())!;
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          isLoading = false;
        });

        // Ouvre et propose le partage
        await SharePlus.instance.share(ShareParams(text: 'Voici le document PDF', files: [XFile(filePath)]));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de chargement')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de chargement')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: "Documents de l'association", body: getBoby());
  }

  Widget getBoby() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : documents.isEmpty
        ? const Center(child: Text('Aucun document disponible.'))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  title: Text(doc['titre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Mis en ligne : ${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.parse(doc['date_mise_en_ligne']))}'),
                  trailing: IconButton(icon: const Icon(Icons.download), onPressed: () => downloadAndShare(doc['url'], '${doc['titre']}.pdf')),
                ),
              );
            },
          );
  }
}
