import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/pages/ajouter_annonce_page.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:sarrazi_asso_clean/services/popup_service.dart';
import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';

class AnnoncesPages extends StatefulWidget {
  const AnnoncesPages({super.key});

  @override
  State<AnnoncesPages> createState() => _AnnoncesPagesState();
}

class _AnnoncesPagesState extends State<AnnoncesPages> {
  List annonces = [];
  bool loading = true;
  String? utilisateur;

  @override
  void initState() {
    super.initState();
    chargerAnnonces();
  }

  Future<void> chargerAnnonces() async {
    setState(() {
      loading = true;
    });
    final response = await HttpService.chargerAnnonces();
    if (response.isSuccess) {
      setState(() {
        annonces = response.data;
      });
    } else {
      if (!mounted) return;
      PopupService.showErrorMessage(context, response.data?.toString());
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: "Annonces", body: getBody(), floatingButton: getFloatingButton());
  }

  void _openImageFullscreen(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Image + zoom
            InteractiveViewer(minScale: 1.0, maxScale: 5.0, child: Image.network(url, fit: BoxFit.contain)),
            // Bouton fermer
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                height: 50,
                margin: EdgeInsets.only(top: 00),
                alignment: Alignment.center,
                width: 50,
                decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: IconButton(
                  tooltip: 'Fermer',
                  icon: const Icon(Icons.close, color: Colors.white, size: 25),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getBody() {
    return Column(
      children: [
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : annonces.isEmpty
              ? const Center(child: Text('Aucune annonce pour le moment.'))
              : RefreshIndicator(
                  onRefresh: chargerAnnonces,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(8, 8, 8, 60),
                    itemCount: annonces.length,
                    itemBuilder: (context, index) {
                      final a = annonces[index];
                      final date = DateTime.parse(a['date_publication']);
                      final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(date);
                      final categorie = a['categorie']?.toString().toLowerCase();
                      final titre = "${(a['titre'] ?? '').substring(0, 1).toUpperCase() + (a['titre'] ?? '').substring(1)}";
                      final photo = (a['photo'] ?? '').toString().trim();
                      final hasPhoto = photo.isNotEmpty;
                      final photoUrl = hasPhoto ? 'https://www.association-sarrazi.fr/uploads_annonces/$photo' : '';

                      return Card(
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          spacing: 0,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              color: Colors.blue[800],
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  spacing: 10,
                                  children: [
                                    Icon(
                                      categorie == 'don'
                                          ? Icons.volunteer_activism
                                          : categorie == 'vente'
                                          ? Icons.sell_outlined
                                          : categorie == 'bon plan'
                                          ? Icons.thumb_up_outlined
                                          : categorie == 'service'
                                          ? Icons.real_estate_agent_outlined
                                          : Icons.campaign_outlined,
                                      size: 25,
                                      color: Colors.white,
                                    ),
                                    Expanded(
                                      child: Text(
                                        titre,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (hasPhoto) ...[
                              GestureDetector(
                                onTap: () => _openImageFullscreen(photoUrl),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(0),
                                  child: Image.network(
                                    photoUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover, // aperçu "pro" (recadré)
                                    // Optionnel : un petit fallback visuel
                                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              //  value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stack) {
                                      return Container(height: 200, width: double.infinity, alignment: Alignment.center, color: Colors.black12, child: const Text("Impossible de charger l'image"));
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                "Appuyez sur la photo pour l'ouvrir",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                spacing: 10,
                                children: [
                                  Text(a['description'] ?? ''),
                                  Text("Publié par ${a['auteur_nom'] ?? 'Inconnu'} le $formattedDate", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget? getFloatingButton() {
    return FloatingActionButton(
      onPressed: _ajouterAnnonce,
      tooltip: 'Ajouter une annonce',
      shape: const CircleBorder(),
      backgroundColor: Colors.blue[800],
      foregroundColor: Colors.white,
      child: const Icon(Icons.add),
    );
  }

  Future<void> _ajouterAnnonce() async {
    if (sharedPreferences.getString('nom')?.isEmpty ?? true) {
      await showModalBottomSheet(context: context, builder: (context) => const LoginBottomSheet(), isScrollControlled: true);
      setState(() {
        utilisateur = sharedPreferences.getString('nom');
      });
    }

    if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
      if (!context.mounted) return;
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AjouterAnnoncePage()));
      if (result == true) chargerAnnonces();
    }
  }
}
