import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sarrazi_asso_clean/extensions/string_extensions.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:sarrazi_asso_clean/services/popup_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ArtisansPage extends StatefulWidget {
  const ArtisansPage({super.key});

  @override
  State<ArtisansPage> createState() => _ArtisansPageState();
}

class _ArtisansPageState extends State<ArtisansPage> {
  List<dynamic> artisans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    chargerArtisans();
  }

  Future<void> chargerArtisans() async {
    setState(() {
      isLoading = true;
    });

    final response = await HttpService.chargerArtisans();
    if (response.isSuccess) {
      setState(() {
        artisans = response.data;
        artisans = artisans.toList().sortedBy(
          (x) =>
              (x['intitule'].toString().contains(':')
                      ? x['intitule'].split(':')[1]
                      : x['intitule'])
                  .toString()
                  .toLowerCase()
                  .trimLeft(),
        );
      });
    } else {
      if (!mounted) return;
      PopupService.showErrorMessage(context, response.data?.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Impossible d\'ouvrir le lien : $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Artisans",
      body: getBody(),
      message:
          "Si vous souhaitez ajouter ou modifier votre activité, n'hésitez pas à nous contacter !",
      withContact: true,
    );
  }

  Widget getBody() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: artisans.length,
            itemBuilder: (context, index) {
              final artisan = artisans[index];
              var titreArtisan = artisan['intitule']
                  .toString()
                  .split(':')
                  .sublist(1)
                  .join('')
                  .trim();
              titreArtisan = titreArtisan.capitalize();
              var descriptionArtisan = artisan['intitule']
                  .split(':')[0]
                  .toString()
                  .trim();
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.fromLTRB(15, 5, 10, 5),
                  titleAlignment: ListTileTitleAlignment.top,
                  leading: Container(
                    height: 40,
                    margin: EdgeInsets.only(top: 6),
                    alignment: Alignment.center,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Color(
                        ((index + 1) * 0.1547 * 0xFFFFFF).toInt(),
                      ).withAlpha(255),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      (artisan['intitule'].toString().contains(':')
                              ? artisan['intitule'].split(':')[1]
                              : artisan['intitule'])
                          .trim()
                          .substring(0, 1)
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    titreArtisan,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                  subtitle: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(descriptionArtisan, style: TextStyle(fontSize: 14)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchURL(artisan['lien']),
                          icon: Icon(Icons.open_in_new),
                          label: Text('Visiter le site'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Color(0xFF00838F),
                            foregroundColor: Color(0xFF00838F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
