import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ForceUpdatePage extends StatelessWidget {

  void openStore() async {
    final url = Platform.isAndroid
    ? "https://play.google.com/store/apps/details?id=fr.sarrazi.asso"
    : "https://apps.apple.com/app/id6754931679";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Mise à jour requise",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                "Veuillez mettre à jour l'application pour continuer.",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: openStore,
                child: Text("Mettre à jour"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}