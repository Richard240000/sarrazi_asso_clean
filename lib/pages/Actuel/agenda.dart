import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AgendaPage extends StatefulWidget {
  @override
  _AgendaPageState createState() => _AgendaPageState();
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
      final response = await http.get(
        Uri.parse('https://www.association-sarrazi.fr/get_evenements.php'),
      );

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : evenements.isEmpty
          ? Center(child: Text("Aucun événement à venir"))
          : ListView.builder(
        itemCount: evenements.length,
        itemBuilder: (context, index) {
          final evt = evenements[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              title: Text(evt['titre']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📍 ${evt['lieu'] ?? 'Lieu non précisé'}"),
                  Text("📅 ${evt['date_event']}"),
                  SizedBox(height: 5),
                  Text(
                      evt['description'] ?? '', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}