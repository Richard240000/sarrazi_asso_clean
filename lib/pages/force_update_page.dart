import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key, this.storeUrl, this.message});

  final String? storeUrl;
  final String? message;

  Future<void> _openStore() async {
    final defaultUrl = Platform.isAndroid
        ? 'https://play.google.com/store/apps/details?id=fr.sarrazi.asso'
        : 'https://apps.apple.com/app/id6754931679';

    final uri = Uri.parse(storeUrl ?? defaultUrl);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Image.asset('assets/logoS.png')),
                const SizedBox(height: 30),
                const Text(
                  'Mise à jour requise',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  message ??
                      'Veuillez mettre à jour l’application pour continuer.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _openStore,
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 25,
                  ),
                  label: const Text(
                    'Mettre à jour',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    elevation: 5,
                    backgroundColor: Colors.blue[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
