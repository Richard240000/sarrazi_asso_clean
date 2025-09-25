import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
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
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    try {
      final response = await http.get(Uri.parse('https://www.association-sarrazi.fr/get_documents.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          documents = data;
          isLoading = false;
        });
      } else {
        throw Exception("Erreur de chargement");
      }
    } catch (e) {
      print('Erreur chargement : $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> downloadAndShare(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Directory dir;
        if (Platform.isAndroid) {
          dir = (await getExternalStorageDirectory())!;
        } else if (Platform.isIOS) {
          dir = await getApplicationDocumentsDirectory();
        } else {
          throw UnsupportedError("Plateforme non supportée");
        }

        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Ouvre et propose le partage
        await OpenFile.open(filePath);
        await Share.shareXFiles([XFile(filePath)], text: 'Voici le document PDF');
      } else {
        print('Erreur téléchargement : ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur téléchargement : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
          ? const Center(child: Text('Aucun document disponible.'))
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
        itemCount: documents.length + 1, // +1 pour le titre
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: const [
                Text(
                  'Documents de l\'association',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
              ],
            );
          }

          final doc = documents[index - 1];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
              title: Text(doc['titre'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Mis en ligne : ${doc['date_mise_en_ligne']}'),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => downloadAndShare(doc['url'], '${doc['titre']}.pdf'),
              ),
            ),
          );
        },
      ),
    );
  }
}
