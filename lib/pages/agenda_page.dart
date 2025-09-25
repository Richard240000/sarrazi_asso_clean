import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:http/http.dart' as http;

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  List<dynamic> evenements = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEvenements();
  }

  Future<void> fetchEvenements() async {
    try {
      final response = await http.get(Uri.parse('https://www.association-sarrazi.fr/get_evenements.php'));

      if (response.statusCode == 200) {
        print("Réponse serveur : ${response.body}");
        setState(() {
          evenements = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Erreur de chargement');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        evenements = [];
      });
      print('Erreur attrapée : $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du chargement des événements'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: "Agenda des événements", body: getBody());
  }

  Widget getBody() {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : evenements.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text("Aucun événement à venir", style: TextStyle(fontSize: 18)),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10),
            itemCount: evenements.length,
            itemBuilder: (context, index) {
              final evt = evenements[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  title: Text(evt['titre'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Row(children: [Icon(Icons.location_on, size: 16), SizedBox(width: 5), Text(evt['lieu'] ?? 'Lieu non précisé')]),
                      SizedBox(height: 5),
                      Row(children: [Icon(Icons.calendar_today, size: 16), SizedBox(width: 5), Text(evt['date_event'])]),
                      SizedBox(height: 8),
                      Text(evt['description'] ?? '', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
