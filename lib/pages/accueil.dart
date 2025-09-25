
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'afficher_annonces.dart';
//import 'afficher_idees.dart';
import 'documents.dart';
import 'information.dart';
import 'annuaire.dart';
import 'agenda.dart';
import 'artisans.dart';
import 'login1_page.dart';

class AccueilPage extends StatelessWidget {
  final Function(Widget) onTilePressed;

  const AccueilPage({Key? key, required this.onTilePressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0), // ✅ Coins arrondis
            child: Image.asset(
              'assets/logoS.png',
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
        backgroundColor: Colors.grey[200],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0), // ✅ Descend les tuiles
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12.0,
          crossAxisSpacing: 12.0,
          childAspectRatio: 0.9,
          children: [
            _buildTile(
              label: 'Alerte-Info',
              icon: Icons.campaign,
              color: Color(0xFF1A237E),
              onTap: () => onTilePressed(InformationPage()),
            ),
            _buildTile(
              label: 'Documents',
              icon: Icons.picture_as_pdf,
              color: Color(0xFF00695C),
              onTap: () => onTilePressed(DocumentsPage()),
            ),
            _buildTile(
              label: 'Annuaire',
              icon: Icons.contact_phone,
              color: Color(0xFF4527A0),
              onTap: () => onTilePressed(AnnuairePage()),
            ),
            _buildTile(
              label: 'Agenda',
              icon: Icons.event,
              color: Color(0xFFAD1457),
              onTap: () => onTilePressed(AgendaPage()),
            ),
            _buildTile(
              label: 'Artisans',
              icon: Icons.handyman,
              color: Color(0xFFEF6C00),
              onTap: () => onTilePressed(ArtisansPage()),
            ),
            _buildTile(
              label: 'Annonces',
              icon: Icons.announcement,
              color: Color(0xFF2E7D32),
              onTap: () => onTilePressed(AfficherAnnoncesPage()),
            ),
            //_buildTile(
            //  label: 'Vigilance / Voisins',
            //  icon: Icons.lightbulb_outline,
            //  color: Color(0xFF1565C0),
            //  onTap: () => onTilePressed(AfficherIdeesPage()),
            // ),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
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
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
