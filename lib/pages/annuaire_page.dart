import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/pages/base_page.dart';

class AnnuairePage extends StatefulWidget {
  const AnnuairePage({super.key});

  @override
  State<AnnuairePage> createState() => _AnnuairePageState();
}

class _AnnuairePageState extends State<AnnuairePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _annuaire = [];
  bool _isLoading = false;

  Future<void> _searchAnnuaire(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse('https://www.association-sarrazi.fr/recherche_annuaire.php?search=$query'));

      if (response.statusCode == 200) {
        setState(() {
          _annuaire = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        _showError('Erreur lors du chargement');
      }
    } catch (e) {
      _showError('Erreur de connexion');
    }
  }

  void _showError(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: "Annuaire", body: getBody());
  }

  Widget getBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, rue...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: _searchAnnuaire,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _annuaire.isEmpty
                ? Center(child: Text('Aucun résultat', style: GoogleFonts.poppins()))
                : ListView.builder(itemCount: _annuaire.length, itemBuilder: (context, index) => _buildMemberCard(_annuaire[index])),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${member['prenom']} ${member['nom']}",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.home, "${member['rue']} - ${member['numero']}"),
            _buildInfoRow(Icons.email, member['mail']),
            _buildInfoRow(Icons.phone, member['portable']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14))),
        ],
      ),
    );
  }
}
