import 'package:flutter/material.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/pages/agenda_page.dart';
import 'package:sarrazi_asso_clean/pages/alertes_info_page.dart';
import 'package:sarrazi_asso_clean/pages/annonces_page.dart';
import 'package:sarrazi_asso_clean/pages/annuaire_page.dart';
import 'package:sarrazi_asso_clean/pages/artisans_page.dart';
import 'package:sarrazi_asso_clean/pages/documents_page.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';
import 'package:sarrazi_asso_clean/pages/reset_password_page.dart';
import 'package:sarrazi_asso_clean/pages/association_page.dart';
//import 'package:sarrazi_asso_clean/pages/publications.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  String? utilisateur;

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
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
      child: Column(
        children: [
          Flexible(flex: 1, child: Image.asset('assets/logoS.png', fit: BoxFit.contain)),
          Flexible(
            flex: 3,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
              childAspectRatio: 0.9,
              children: [
                _buildTile(
                  label: 'L\'association',
                  icon: Icons.groups,
                  color: const Color(0xFF455A64),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssociationPage())),
                ),
                _buildTile(
                  label: 'Alerte-Info',
                  icon: Icons.campaign,
                  color: const Color(0xFF1A237E),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AlertesInfoPage())),
                ),
                _buildTile(
                  label: 'Documents',
                  icon: Icons.picture_as_pdf,
                  color: const Color(0xFF00695C),
                  isSecure: true,
                  onTap: () async {
                    if (sharedPreferences.getString('nom')?.isEmpty ?? true) {
                      await showModalBottomSheet(context: context, builder: (context) => LoginBottomSheet(), isScrollControlled: true);
                      setState(() {
                        utilisateur = sharedPreferences.getString('nom');
                      });
                    }

                    if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
                      if (!mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (context) => DocumentsPage()));
                    }
                  },
                ),
                _buildTile(
                  label: 'Annuaire',
                  icon: Icons.contact_phone,
                  color: const Color(0xFF4527A0),
                  isSecure: true,
                  onTap: () async {
                    if (sharedPreferences.getString('nom')?.isEmpty ?? true) {
                      await showModalBottomSheet(context: context, builder: (context) => LoginBottomSheet(), isScrollControlled: true);
                      setState(() {
                        utilisateur = sharedPreferences.getString('nom');
                      });
                    }

                    if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
                      if (!mounted) return;
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AnnuairePage()));
                    }
                  },
                ),
                _buildTile(
                  label: 'Agenda',
                  icon: Icons.event,
                  color: const Color(0xFFAD1457),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AgendaPage())),
                ),
                _buildTile(
                  label: 'Artisans',
                  icon: Icons.handyman,
                  color: const Color(0xFFEF6C00),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArtisansPage())),
                ),
                _buildTile(
                  label: 'Annonces',
                  icon: Icons.announcement,
                  color: const Color(0xFF2E7D32),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnnoncesPages())),
                ),

                // 🔵 NOUVELLE TUILE TEMPORAIRE PUBLICATIONS
                // _buildTile(
                //   label: 'Publications',
                //   icon: Icons.forum,
                //   color: const Color(0xFF1976D2),
                //   isSecure: true,
                //   onTap: () async {
                //     if (sharedPreferences.getString('nom')?.isEmpty ?? true) {
                //       await showModalBottomSheet(
                //         context: context,
                //         builder: (context) => LoginBottomSheet(),
                //         isScrollControlled: true,
                //       );
                //       setState(() {
                //         utilisateur = sharedPreferences.getString('nom');
                //       });
                //     }

                //     if (sharedPreferences.getString('nom')?.isNotEmpty ?? false) {
                //       if (!mounted) return;
                //       Navigator.push(context, MaterialPageRoute(builder: (context) => PublicationsPage()));
                //     }
                //   },
                // ),
              ],
            ),
          ),
        ],
      ), // ✅ ferme SingleChildScrollView
    ); // ✅ ferme Padding
  }

  Widget _buildTile({required String label, required IconData icon, required Color color, required VoidCallback onTap, bool isSecure = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            isSecure
                ? const Align(
                    alignment: Alignment.topRight,
                    child: Icon(Icons.lock, size: 16.0, color: Colors.white),
                  )
                : const SizedBox(height: 16),
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
