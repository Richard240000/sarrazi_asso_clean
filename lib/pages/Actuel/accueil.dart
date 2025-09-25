import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'information.dart';
import 'documents.dart';
import 'annuaire.dart';
import 'afficher_annonces.dart';
import 'login_page.dart';
import 'afficher_idees.dart';
import 'artisans.dart';
import 'agenda.dart';

class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Association des Habitants de Sarrazi'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Déconnexion'),
                  content: Text('Voulez-vous vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Oui'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('email');
                await prefs.remove('nom');
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InformationPage()),
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.campaign, color: Colors.orange.shade900),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Consultez les dernières infos dans la rubrique 'Alerte-Info'",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.count(
                crossAxisCount: 3, // Changé de 2 à 3 pour 3 tuiles par ligne
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9, // Ajusté pour mieux s'adapter à 3 colonnes
                children: [
                  _buildMenuItem(context, Icons.campaign, 'Alerte-Info', InformationPage()),
                  _buildMenuItem(context, Icons.description, 'Documents', DocumentsPage()),
                  _buildMenuItem(context, Icons.event, 'Agenda', AgendaPage()),
                  _buildMenuItem(context, Icons.people, 'Annuaire', AnnuairePage()),
                  _buildMenuItem(
                    context,
                    Icons.shopping_bag,
                    'Annonces\nBons Plans',
                    Container(),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final email = prefs.getString('email');

                      if (email == null) {
                        final success = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LoginPage()),
                        );

                        if (success == true) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AfficherAnnoncesPage()),
                          );
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AfficherAnnoncesPage()),
                        );
                      }
                    },
                  ),
                  _buildMenuItem(context, Icons.lightbulb_outline, 'Idée\nProposition', AfficherIdeesPage()),
                  _buildMenuItem(context, Icons.person_pin_circle, 'Ils habitent\nle hameau', ArtisansPage()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context,
      IconData icon,
      String label,
      Widget page, {
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.green), // Taille d'icône réduite pour 3 colonnes
            SizedBox(height: 8),
            Text(
              label, 
              textAlign: TextAlign.center, 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12, // Taille de police légèrement réduite
              ),
            ),
          ],
        ),
      ),
    );
  }
}