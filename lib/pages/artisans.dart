import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ArtisansPage extends StatefulWidget {
  const ArtisansPage({super.key});

  @override
  _ArtisansPageState createState() => _ArtisansPageState();
}

class _ArtisansPageState extends State<ArtisansPage> {
  List<dynamic> artisans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchArtisans();
  }

  Future<void> fetchArtisans() async {
    try {
      final response = await http.get(Uri.parse(
          'https://www.association-sarrazi.fr/liste_artisans.php'));

      if (response.statusCode == 200) {
        setState(() {
          artisans = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Erreur serveur');
      }
    } catch (e) {
      print('Erreur : $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Impossible d\'ouvrir le lien : $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: artisans.length,
            itemBuilder: (context, index) {
              final artisan = artisans[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_pin_circle, 
                              size: 32, 
                              color: Colors.brown),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              artisan['intitule'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchURL(artisan['lien']),
                          icon: Icon(Icons.open_in_new),
                          label: Text('Visiter le site'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}