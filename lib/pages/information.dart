import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/actualite.dart';
import '../services/actualite_service.dart';
import 'webview_page.dart';
import 'package:intl/intl.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

  @override
  _InformationPageState createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  List<Actualite> actualites = [];
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  String _formatDate(DateTime date) {
    try {
      return _dateFormat.format(date);
    } catch (e) {
      return date.toString();
    }
  }

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
    return Column(
      children: [
        AppBar(
          title: Text('Infos pratiques'),
          automaticallyImplyLeading: false,
          elevation: 0,
        ),
        Expanded(
          child: actualites.isEmpty
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: loadActualites,
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: actualites.length,
              itemBuilder: (context, index) {
                final actualite = actualites[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Début des ajouts pour nature et nom
                        if (actualite.nature != null && actualite.nature!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              actualite.nature!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),

                        if (actualite.nom != null && actualite.nom!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'De: ${actualite.nom!}',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        // Fin des ajouts

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Html(
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
                                    margin: Margins.only(bottom: 6),
                                  ),
                                  "a": Style(
                                    color: Colors.teal,
                                    textDecoration: TextDecoration.underline,
                                  ),
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            _formatDate(actualite.dateAjout),
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
          ),
        ),
      ],
    );
  }
}
