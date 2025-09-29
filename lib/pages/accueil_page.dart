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
      padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0), // ✅ Descend les tuiles
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0), // ✅ Coins arrondis
            child: Image.asset('assets/logoS.png', fit: BoxFit.contain),
          ),
          GridView.count(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            childAspectRatio: 0.9,
            children: [
              _buildTile(
                label: 'Alerte-Info',
                icon: Icons.campaign,
                color: Color(0xFF1A237E),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AlertesInfoPage())),
              ),
              _buildTile(
                label: 'Documents',
                icon: Icons.picture_as_pdf,
                color: Color(0xFF00695C),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DocumentsPage())),
              ),
              _buildTile(
                label: 'Annuaire',
                icon: Icons.contact_phone,
                color: Color(0xFF4527A0),
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
                color: Color(0xFFAD1457),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AgendaPage())),
              ),
              _buildTile(
                label: 'Artisans',
                icon: Icons.handyman,
                color: Color(0xFFEF6C00),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArtisansPage())),
              ),
              _buildTile(
                label: 'Annonces',
                icon: Icons.announcement,
                color: Color(0xFF2E7D32),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AnnoncesPages())),
              ),
              //_buildTile(
              //  label: 'Vigilance / Voisins',
              //  icon: Icons.lightbulb_outline,
              //  color: Color(0xFF1565C0),
              //  onTap: () => onTilePressed(AfficherIdeesPage()),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
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
      ),
    );
  }
}
