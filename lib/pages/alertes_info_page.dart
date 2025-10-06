import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:sarrazi_asso_clean/models/actualite.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/pages/webview_page.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:sarrazi_asso_clean/services/popup_service.dart';

class AlertesInfoPage extends StatefulWidget {
  const AlertesInfoPage({super.key});

  @override
  State<AlertesInfoPage> createState() => _AlertesInfoPageState();
}

class _AlertesInfoPageState extends State<AlertesInfoPage> {
  List<Actualite> actualites = [];
  bool isLoading = false;
  String message = "";

  @override
  void initState() {
    super.initState();
    chargerActualites();
  }

  Future<void> chargerActualites() async {
    setState(() {
      isLoading = true;
      message = "";
    });
    final response = await HttpService.chargerActualites();
    if (response.isSuccess) {
      setState(() {
        if (response.data?.isNotEmpty ?? false) {
          actualites = List<Actualite>.from(response.data.map((x) => Actualite.fromJson(x)));
        }
      });
    } else {
      if (!mounted) return;
      PopupService.showErrorMessage(context, response.data?.toString());
    }
    setState(() {
      if (actualites.isEmpty) {
        message = "Aucune donnée disponible";
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: 'Infos pratiques', body: getBody());
  }

  Widget getBody() {
    return Column(
      children: [
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: chargerActualites,
                  child: message.isNotEmpty
                      ? Center(child: Text(message, textAlign: TextAlign.center))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12.0),
                          itemCount: actualites.length,
                          itemBuilder: (context, index) {
                            final actualite = actualites[index];
                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800]),
                                        ),
                                      ),

                                    if (actualite.nom != null && actualite.nom!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          'De: ${actualite.nom!}',
                                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600]),
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
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => WebViewPage(url: url)));
                                              }
                                            },
                                            style: {
                                              "body": Style(fontSize: FontSize(16), color: Colors.black87, margin: Margins.only(bottom: 6)),
                                              "a": Style(color: Colors.teal, textDecoration: TextDecoration.underline),
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format((actualite.dateAjout)),
                                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
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
