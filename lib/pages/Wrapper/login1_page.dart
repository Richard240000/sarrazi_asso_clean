import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/pages/login1_page.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login1_page.dart'; // <- ajout

class AnnuairePage extends StatefulWidget {
  const AnnuairePage({super.key});

  @override
  _AnnuairePageState createState() => _AnnuairePageState();
}

class _AnnuairePageState extends State<AnnuairePage> {
  List annuaire = [];

  @override
  void initState() {
    super.initState();
    _verifierConnexionEtCharger();
  }

  Future<void> _verifierConnexionEtCharger() async {
    final prefs = await SharedPreferences.getInstance();
    final isConnected = prefs.getBool('isConnectedToAnnuaire') ?? false;

    if (!isConnected) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Login1Page()));
    } else {
      _chargerAnnuaire();
    }
  }

  Future<void> _chargerAnnuaire() async {
    final response = await http.get(Uri.parse('https://www.association-sarrazi.fr/liste_annuaire.php'));

    if (response.statusCode == 200) {
      setState(() {
        annuaire = json.decode(response.body);
      });
    } else {
      throw Exception('Échec du chargement de l\'annuaire');
    }
  }

  Future<void> _envoyerEmail(String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    await launchUrl(emailLaunchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Annuaire des voisins')),
      body: ListView.builder(
        itemCount: annuaire.length,
        itemBuilder: (context, index) {
          final personne = annuaire[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('${personne['prenom']} ${personne['nom']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${personne['rue']}, ${personne['numero']}'),
                  Text('${personne['portable']}'),
                  GestureDetector(onTap: () => _envoyerEmail(personne['mail']), child: Text('${personne['mail']}', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
