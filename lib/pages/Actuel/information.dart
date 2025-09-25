import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/actualite.dart';
import '../services/actualite_service.dart';
import 'webview_page.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  _InformationPageState createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  List<Actualite> actualites = [];

  @override
  void initState() {
    super.initState();
    loadActualites();
  }

  Future<void> loadActualites() async {
    final data = await ActualiteService().fetchActualites();
    setState(() {
      actualites = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Infos pratiques'),
        backgroundColor: Colors.teal,
      ),
      body: actualites.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: actualites.length,
              itemBuilder: (context, index) {
                final actualite = actualites[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Html(
                          data: actualite.texte,
                          onLinkTap: (url, attributes, element) {
                            if (url != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebViewPage(url: url),
                                ),
                              );
                            }
                          },
                          style: {
                            "body": Style(
                              fontSize: FontSize(16),
                              color: Colors.black87,
                            ),
                            "a": Style(
                              color: Colors.teal,
                              textDecoration: TextDecoration.underline,
                            ),
                          },
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            actualite.dateAjout,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
