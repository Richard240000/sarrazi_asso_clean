import 'package:flutter/material.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/pages/agenda_page.dart';
import 'package:sarrazi_asso_clean/pages/annonces_page.dart';
import 'package:sarrazi_asso_clean/pages/annuaire_page.dart';
import 'package:sarrazi_asso_clean/pages/artisans_page.dart';
import 'package:sarrazi_asso_clean/pages/documents_page.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';
import 'package:sarrazi_asso_clean/pages/association_page.dart';
import 'package:sarrazi_asso_clean/pages/alerte_signalement.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  String? utilisateur;
  Map<String, dynamic>? bandeauMaj;
  bool chargementBandeau = true;

  @override
  void initState() {
    super.initState();
    utilisateur = sharedPreferences.getString('nom');
    chargerBandeau();
  }

  Future<void> chargerBandeau() async {
    var result = await HttpService.chargerBandeauMaj();

    if (!mounted) return;

    if (result.isSuccess && result.data is Map<String, dynamic>) {
      setState(() {
        bandeauMaj = Map<String, dynamic>.from(result.data);
        chargementBandeau = false;
      });
    } else {
      setState(() {
        bandeauMaj = null;
        chargementBandeau = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onVisibilityGained: () {
        setState(() {
          utilisateur = sharedPreferences.getString('nom');
        });
      },
      child: BasePage(title: "", body: getBody(), isHome: true),
    );
  }

  Widget getBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset('assets/logoS.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 8),

            _buildBandeauMaj(),

            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      child: _buildTile(
                        label: 'Alerte & Signalement',
                        icon: Icons.notifications_active,
                        color: const Color(0xFF1A237E),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AlerteSignalementPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildTile(
                        label: 'L\'association',
                        icon: Icons.groups,
                        color: const Color(0xFF455A64),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AssociationPage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildTile(
                        label: 'Annuaire',
                        icon: Icons.contact_phone,
                        color: const Color(0xFF4527A0),
                        isSecure: true,
                        onTap: () async {
                          if (sharedPreferences.getString('nom')?.isEmpty ??
                              true) {
                            await showModalBottomSheet(
                              context: context,
                              builder: (context) => LoginBottomSheet(),
                              isScrollControlled: true,
                            );
                            setState(() {
                              utilisateur = sharedPreferences.getString('nom');
                            });
                          }

                          if (sharedPreferences.getString('nom')?.isNotEmpty ??
                              false) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnnuairePage(),
                              ),
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildTile(
                        label: 'Documents',
                        icon: Icons.picture_as_pdf,
                        color: const Color(0xFF00695C),
                        isSecure: true,
                        onTap: () async {
                          if (sharedPreferences.getString('nom')?.isEmpty ??
                              true) {
                            await showModalBottomSheet(
                              context: context,
                              builder: (context) => LoginBottomSheet(),
                              isScrollControlled: true,
                            );
                            setState(() {
                              utilisateur = sharedPreferences.getString('nom');
                            });
                          }

                          if (sharedPreferences.getString('nom')?.isNotEmpty ??
                              false) {
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DocumentsPage(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildTile(
                        label: 'Agenda',
                        icon: Icons.event,
                        color: const Color(0xFFAD1457),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AgendaPage()),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildTile(
                        label: 'Artisans',
                        icon: Icons.handyman,
                        color: const Color(0xFFEF6C00),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArtisansPage(),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _buildTile(
                        label: 'Annonces',
                        icon: Icons.announcement,
                        color: const Color(0xFF2E7D32),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnoncesPages(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandeauMaj() {
    if (chargementBandeau || bandeauMaj == null) {
      return const SizedBox.shrink();
    }

    if (bandeauMaj!['enabled'] != true) {
      return const SizedBox.shrink();
    }

    final String message =
        bandeauMaj!['message']?.toString() ?? 'Nouvelle version disponible';
    String buttonUrl = '';

    if (Platform.isAndroid) {
      buttonUrl = bandeauMaj!['android_url']?.toString() ?? '';
    } else if (Platform.isIOS) {
      buttonUrl = bandeauMaj!['ios_url']?.toString() ?? '';
    }

    Future<void> ouvrirStore() async {
      if (buttonUrl.isEmpty) return;
      final uri = Uri.parse(buttonUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    return GestureDetector(
      onTap: ouvrirStore,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.system_update_alt,
                size: 15,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(width: 6),

            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12.5, height: 1.15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 6),

            TextButton(
              onPressed: ouvrirStore,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "MAJ",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSecure = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            isSecure
                ? const Align(
                    alignment: Alignment.topRight,
                    child: Icon(Icons.lock, size: 16.0, color: Colors.white),
                  )
                : const SizedBox(height: 16),
            const SizedBox(height: 4),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32.0, color: Colors.white),
                const SizedBox(height: 10.0),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
