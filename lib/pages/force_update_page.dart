import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ForceUpdatePage extends StatelessWidget {
  void openStore() async {
    final url = Platform.isAndroid ? "https://play.google.com/store/apps/details?id=fr.sarrazi.asso" : "https://apps.apple.com/app/id6754931679";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: Image.asset('assets/logoS.png')),
              SizedBox(height: 30),
              Text("Mise à jour requise", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text("Veuillez mettre à jour l'application pour continuer.", textAlign: TextAlign.center),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: openStore,
                icon: const Icon(Symbols.download, color: Colors.white, size: 25),
                label: Text('Mettre à jour', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10)),
                  elevation: WidgetStatePropertyAll(5),
                  backgroundColor: WidgetStatePropertyAll(Colors.blue[800]),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
