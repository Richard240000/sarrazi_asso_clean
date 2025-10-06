import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:sarrazi_asso_clean/extensions/string_extensions.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:sarrazi_asso_clean/services/popup_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnuairePage extends StatefulWidget {
  const AnnuairePage({super.key});

  @override
  State<AnnuairePage> createState() => _AnnuairePageState();
}

class _AnnuairePageState extends State<AnnuairePage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _annuaire = [];
  bool _isLoading = false;
  String _message = "";

  Future<void> _searchAnnuaire(String query) async {
    setState(() {
      _isLoading = true;
      _annuaire = [];
      _message = "";
    });

    if (query.trim().isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final response = await HttpService.rechercheAnnuaire(query);

    if (response.isSuccess) {
      setState(() {
        _annuaire = response.data;
        if (_annuaire.isEmpty) {
          setState(() {
            _message = "Aucun résultat ne correspond à votre recherche";
          });
        }
      });
    } else {
      if (!mounted) return;
      PopupService.showErrorMessage(context, response.data?.toString());
    }

    setState(() {
      _isLoading = false;
    });
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
                : _annuaire.isNotEmpty
                ? ListView.builder(itemCount: _annuaire.length, itemBuilder: (context, index) => _buildMemberCard(_annuaire[index]))
                : Center(
                    child: Text(_message, style: GoogleFonts.poppins(), textAlign: TextAlign.center),
                  ),
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
              "${member['prenom']?.toString().trim().capitalize()} ${member['nom']?.toString().trim().capitalize()}",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]),
            ),
            const SizedBox(height: 8),
            member['numero']?.isNotEmpty ?? false ? _buildInfoRow(Icons.home, "${member['numero']} ${member['rue']}") : _buildInfoRow(Icons.home, "${member['rue']}"),
            member['mail']?.isNotEmpty
                ? InkWell(
                    child: _buildInfoRow(Icons.email, member['mail']),
                    onTap: () async {
                      final Email email = Email(recipients: [member['mail']], isHTML: false);

                      await FlutterEmailSender.send(email);
                    },
                  )
                : SizedBox.shrink(),
            member['portable']?.isNotEmpty ?? false
                ? InkWell(
                    child: _buildInfoRow(Icons.phone, member['portable']),
                    onTap: () async {
                      await launchUrl(Uri.parse("tel:${member['portable']}"));
                    },
                  )
                : SizedBox.shrink(),
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
