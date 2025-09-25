import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnnuairePage extends StatefulWidget {
  const AnnuairePage({super.key});

  @override
  _AnnuairePageState createState() => _AnnuairePageState();
}

class _AnnuairePageState extends State<AnnuairePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _annuaire = [];
  bool _isLoading = false;

  Future<void> _searchAnnuaire(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://www.association-sarrazi.fr/recherche_annuaire.php?search=$query'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _annuaire = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement de l\'annuaire')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Une erreur est survenue')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildMemberCard(dynamic member) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${member['prenom']} ${member['nom']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text("${member['rue']} - ${member['numero']}"),
            const SizedBox(height: 4),
            Text("📧 ${member['mail']}"),
            const SizedBox(height: 4),
            Text("📱 ${member['portable']}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Annuaire des Membres"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher par nom, prénom, nom de rue...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchAnnuaire(_searchController.text),
                ),
              ),
              onSubmitted: _searchAnnuaire,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_annuaire.isEmpty)
              const Text('Aucun résultat trouvé.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _annuaire.length,
                  itemBuilder: (context, index) {
                    return _buildMemberCard(_annuaire[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
