import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_detector_v2/focus_detector_v2.dart';
import 'package:sarrazi_asso_clean/main.dart';
import 'package:sarrazi_asso_clean/pages/agenda_page.dart';
import 'package:sarrazi_asso_clean/pages/annonces_page.dart';
import 'package:sarrazi_asso_clean/pages/annuaire_page.dart';
import 'package:sarrazi_asso_clean/pages/artisans_page.dart';
import 'package:sarrazi_asso_clean/pages/documents_page.dart';
import 'package:sarrazi_asso_clean/pages/association_page.dart';
import 'package:sarrazi_asso_clean/pages/alerte_signalement.dart';
import 'package:sarrazi_asso_clean/pages/phototheque_page.dart';
import 'package:sarrazi_asso_clean/widgets/login_bottom_sheet.dart';

class BasePage extends StatefulWidget {
  const BasePage({
    super.key,
    required this.title,
    required this.body,
    this.isHome = false,
    this.floatingButton,
    this.isBottomBarVisible = true,
    this.message,
    this.withContact = false,
  });

  final String title;
  final Widget body;
  final Widget? floatingButton;
  final bool isHome;
  final bool isBottomBarVisible;
  final String? message;
  final bool withContact;

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  String? utilisateur;
  final GlobalKey _menuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return FocusDetector(
      onVisibilityGained: () {
        setState(() {
          utilisateur = sharedPreferences.getString('nom');
        });
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.blue[800],
          title: Text(widget.title),
          automaticallyImplyLeading: true,
          actions: [
            utilisateur?.isNotEmpty ?? false
                ? IconButton(
                    onPressed: () async {
                      await sharedPreferences.remove('user_id');
                      await sharedPreferences.remove('nom');
                      setState(() {
                        utilisateur = sharedPreferences.getString('nom');
                      });
                      if (!widget.isHome) {
                        if (!context.mounted) return;
                        Navigator.popUntil(context, (x) => x.isFirst);
                      }
                    },
                    icon: const Icon(Icons.power_settings_new),
                  )
                : const SizedBox.shrink(),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.body),
            widget.message?.isNotEmpty ?? false
                ? GestureDetector(
                    onTap: widget.withContact
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AssociationPage(),
                              ),
                            )
                        : () {},
                    child: Container(
                      color: Colors.blue.withAlpha(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          spacing: 5,
                          children: [
                            Text(
                              widget.message!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.indigo),
                            ),
                            widget.withContact
                                ? InkWell(
                                    child: Icon(Icons.mail, color: Colors.indigo),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AssociationPage(),
                                      ),
                                    ),
                                  )
                                : SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
        floatingActionButton: widget.floatingButton,
        bottomNavigationBar: widget.isBottomBarVisible
            ? Padding(
                padding: EdgeInsets.only(
                  bottom: Platform.isAndroid
                      ? MediaQuery.paddingOf(context).bottom
                      : 0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
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
                                  Icon(
                                    Icons.home,
                                    color: widget.isHome
                                        ? Colors.blue[800]
                                        : const Color(0xff424242),
                                  ),
                                  Text(
                                    "Accueil",
                                    style: TextStyle(
                                      color: widget.isHome
                                          ? Colors.blue[800]
                                          : const Color(0xff424242),
                                    ),
                                  ),
                                ],
                              ),
                              label: const Text(""),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              key: _menuKey,
                              onPressed: () async {
                                final RenderBox button =
                                    _menuKey.currentContext!
                                        .findRenderObject() as RenderBox;
                                final RenderBox overlay =
                                    Overlay.of(context)
                                        .context
                                        .findRenderObject() as RenderBox;

                                final RelativeRect position =
                                    RelativeRect.fromRect(
                                  Rect.fromPoints(
                                    button.localToGlobal(
                                      Offset.zero,
                                      ancestor: overlay,
                                    ),
                                    button.localToGlobal(
                                      button.size.bottomRight(Offset.zero),
                                      ancestor: overlay,
                                    ),
                                  ),
                                  Offset.zero & overlay.size,
                                );

                                final result = await showMenu(
                                  context: context,
                                  color: Colors.blue[800],
                                  position: position,
                                  items: <PopupMenuItem<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'Association',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.groups,
                                              size: 25, color: Colors.white),
                                          Text(
                                            'L\'association',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Alerte-Signalement',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.notifications_active,
                                              size: 25, color: Colors.white),
                                          Text(
                                            'Alertes & Signalements',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Documents',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.picture_as_pdf,
                                              size: 25, color: Colors.white),
                                          Text(
                                            'Documents',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          Icon(Icons.lock,
                                              size: 15, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Annuaire',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.contact_phone,
                                              size: 25, color: Colors.white),
                                          Text(
                                            'Annuaire',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          Icon(Icons.lock,
                                              size: 15, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Agenda',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.event,
                                              size: 25, color: Colors.white),
                                          Text(
                                            'Agenda',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Artisans',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.handyman,
                                              size: 25, color: Colors.white),
                                          Text(
                                            'Artisans',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Annonces',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.announcement,
                                              size: 25, color: Colors.white),
                                          Text(
                                            'Annonces',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Phototheque',
                                      child: Row(
                                        spacing: 10,
                                        children: [
                                          Icon(Icons.photo_library,
                                              size: 25, color: Colors.white),
                                          Text(
                                            'Photothèque',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: '-',
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        spacing: 10,
                                        children: [
                                          Text(
                                            "Version ${version ?? ''}",
                                            style: TextStyle(
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );

                                if (!context.mounted) return;
                                if (result == null) return;

                                switch (result) {
                                  case "Alerte-Signalement":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AlerteSignalementPage(),
                                      ),
                                    );
                                    break;

                                  case "Documents":
                                    if (utilisateur?.isEmpty ?? true) {
                                      await showModalBottomSheet(
                                        context: context,
                                        builder: (context) => LoginBottomSheet(),
                                        isScrollControlled: true,
                                      );
                                      setState(() {
                                        utilisateur =
                                            sharedPreferences.getString('nom');
                                      });
                                    }
                                    if (utilisateur?.isNotEmpty ?? false) {
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DocumentsPage(),
                                        ),
                                      );
                                    }
                                    break;

                                  case "Annuaire":
                                    if (utilisateur?.isEmpty ?? true) {
                                      await showModalBottomSheet(
                                        context: context,
                                        builder: (context) => LoginBottomSheet(),
                                        isScrollControlled: true,
                                      );
                                      setState(() {
                                        utilisateur =
                                            sharedPreferences.getString('nom');
                                      });
                                    }
                                    if (utilisateur?.isNotEmpty ?? false) {
                                      if (!context.mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AnnuairePage(),
                                        ),
                                      );
                                    }
                                    break;

                                  case "Artisans":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ArtisansPage(),
                                      ),
                                    );
                                    break;

                                  case "Association":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AssociationPage(),
                                      ),
                                    );
                                    break;

                                  case "Agenda":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AgendaPage(),
                                      ),
                                    );
                                    break;

                                  case "Annonces":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AnnoncesPages(),
                                      ),
                                    );
                                    break;

                                  case "Phototheque":
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PhotothequePage(),
                                      ),
                                    );
                                    break;
                                }
                              },
                              icon: const Column(
                                children: [
                                  Icon(Icons.menu,
                                      color: Color(0xff424242)),
                                  Text(
                                    "Menu",
                                    style:
                                        TextStyle(color: Color(0xff424242)),
                                  ),
                                ],
                              ),
                              label: const Text(""),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : SizedBox(height: kBottomNavigationBarHeight),
      ),
    );
  }
}