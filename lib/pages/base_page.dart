import 'package:flutter/material.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/pages/agenda_page.dart';
import 'package:sarrazi_asso_clean/pages/alertes_info_page.dart';
import 'package:sarrazi_asso_clean/pages/annonces_page.dart';
import 'package:sarrazi_asso_clean/pages/annuaire_page.dart';
import 'package:sarrazi_asso_clean/pages/artisans_page.dart';
import 'package:sarrazi_asso_clean/pages/documents_page.dart';
import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';

class BasePage extends StatefulWidget {
  const BasePage({super.key, required this.title, required this.body, this.isHome = false, this.floatingButton, this.isBottomBarVisible = true});
  final String title;
  final Widget body;
  final Widget? floatingButton;
  final bool isHome;
  final bool isBottomBarVisible;
  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  String? utilisateur;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onVisibilityGained: () {
        setState(() {
          utilisateur = sharedPreferences.getString('nom');
        });
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          appBar: AppBar(
            foregroundColor: Colors.blue[800],
            title: Text(widget.title),
            automaticallyImplyLeading: true,
            actions: [
              utilisateur?.isNotEmpty ?? false
                  ? IconButton(
                      onPressed: () async {
                        await sharedPreferences.setString("nom", '');
                        setState(() {
                          utilisateur = sharedPreferences.getString('nom');
                        });
                        if (!widget.isHome) {
                          if (!context.mounted) return;
                          Navigator.popUntil(context, (x) => x.isFirst);
                        }
                      },
                      icon: Icon(Icons.power_settings_new),
                    )
                  : SizedBox.shrink(),
            ],
          ),
          body: widget.body,
          floatingActionButton: widget.floatingButton,
          bottomNavigationBar: widget.isBottomBarVisible
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                if (widget.isHome) return;
                                Navigator.popUntil(context, (x) => x.isFirst);
                              },
                              icon: Column(
                                children: [
                                  Icon(Icons.home, color: widget.isHome ? Colors.blue[800] : Color(0xff424242)),
                                  Text("Accueil", style: TextStyle(color: widget.isHome ? Colors.blue[800] : Color(0xff424242))),
                                ],
                              ),
                              label: const Text(""),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () async {
                                final result = await showMenu(
                                  context: context,
                                  color: Colors.blue[800],
                                  position: RelativeRect.fromLTRB(1000.0, 1000.0, 0.0, 0.0),
                                  items: <PopupMenuItem<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'Alerte-Info',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.campaign, size: 25, color: Colors.white),
                                          Text('Alerte-Info', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Documents',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.picture_as_pdf, size: 25, color: Colors.white),
                                          Text('Documents', style: TextStyle(color: Colors.white)),
                                          Icon(Icons.lock, size: 15, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Annuaire',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.contact_phone, size: 25, color: Colors.white),
                                          Text('Annuaire', style: TextStyle(color: Colors.white)),
                                          Icon(Icons.lock, size: 15, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Agenda',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.event, size: 25, color: Colors.white),
                                          Text('Agenda', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Artisans',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.handyman, size: 25, color: Colors.white),
                                          Text('Artisans', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),

                                    const PopupMenuItem<String>(
                                      value: 'Annonces',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.announcement, size: 25, color: Colors.white),
                                          Text('Annonces', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                                if (!context.mounted) return;
                                switch (result) {
                                  case "Alerte-Info":
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => AlertesInfoPage()));
                                    break;
                                  case "Documents":
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => DocumentsPage()));
                                    break;
                                  case "Annuaire":
                                    if (utilisateur?.isEmpty ?? true) {
                                      await showModalBottomSheet(context: context, builder: (context) => LoginBottomSheet(), isScrollControlled: true);
                                      setState(() {
                                        utilisateur = sharedPreferences.getString('nom');
                                      });
                                    }
                                    if (utilisateur?.isNotEmpty ?? false) {
                                      if (!context.mounted) return;
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => AnnuairePage()));
                                    }
                                    break;
                                  case "Artisans":
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => ArtisansPage()));
                                    break;
                                  case "Agenda":
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => AgendaPage()));
                                    break;
                                  case "Annonces":
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => AnnoncesPages()));
                                    break;
                                }
                              },
                              icon: Column(
                                children: [
                                  Icon(Icons.menu, color: Color(0xff424242)),
                                  Text("Menu", style: TextStyle(color: Color(0xff424242))),
                                ],
                              ),
                              label: const Text(""),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : SizedBox.fromSize(),
        ),
      ),
    );
  }
}
