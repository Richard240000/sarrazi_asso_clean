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
    return BasePage(
      title: "Annonces",
      body: getBody(),
      floatingButton: getFloatingButton(),
    );
  }

  void _openImageFullscreen(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            // Image + zoom
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Image.network(
                url,
                fit: BoxFit.contain,
              ),
            ),
            // Bouton fermer
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                tooltip: 'Fermer',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
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
                        itemCount: annonces.length,
                        itemBuilder: (context, index) {
                          final a = annonces[index];
                          final date = DateTime.parse(a['date_publication']);
                          final formattedDate =
                              DateFormat('dd/MM/yyyy à HH:mm').format(date);

                          final photo = (a['photo'] ?? '').toString().trim();
                          final hasPhoto = photo.isNotEmpty;
                          final photoUrl = hasPhoto
                              ? 'https://www.association-sarrazi.fr/uploads_annonces/$photo'
                              : '';

                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a['titre'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(a['description'] ?? ''),
                                  if (hasPhoto) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => _openImageFullscreen(photoUrl),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          photoUrl,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover, // aperçu "pro" (recadré)
                                          // Optionnel : un petit fallback visuel
                                          errorBuilder: (context, error, stack) {
                                            return Container(
                                              height: 200,
                                              width: double.infinity,
                                              alignment: Alignment.center,
                                              color: Colors.black12,
                                              child: const Text(
                                                "Impossible de charger l'image",
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Appuyez sur la photo pour l'ouvrir",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 5),
                                  Text(
                                    "Publié par ${a['auteur_nom'] ?? 'Inconnu'} le $formattedDate",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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
      await showModalBottomSheet(
        context: context,
        builder: (context) => const LoginBottomSheet(),
        isScrollControlled: true,
      );
      setState(() {
        utilisateur = sharedPreferences.getString('nom');
      });
    }

    if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
      if (!context.mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AjouterAnnoncePage()),
      );
      if (result == true) chargerAnnonces();
    }
  }
}
