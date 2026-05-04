import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _message = '';

  Future<void> _searchAnnuaire(String query) async {
    FocusManager.instance.primaryFocus?.unfocus();
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
    return BasePage(title: "Annuaire", body: getBody(), message: "Si vous souhaitez modifier vos coordonnées, n'hésitez pas à nous contacter !", withContact: true);
  }

  Widget getBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 5,
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, rue...',
                    hintStyle: TextStyle(fontSize: 14),
                    //  prefixIcon: Icon(Icons.search, size: 25),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.pink, width: 0.5),
                    ),
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 14),
                  ),
                  onSubmitted: _searchAnnuaire,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _searchAnnuaire(_searchController.text),
                // icon: const Icon(Symbols.search, color: Colors.white, size: 25),
                label: Text('Rechercher', style: TextStyle(color: Colors.white, fontSize: 14)),
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsetsGeometry.symmetric(horizontal: 10, vertical: 14.5)),
                  elevation: WidgetStatePropertyAll(3),
                  backgroundColor: WidgetStatePropertyAll(Colors.blue[800]),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                ),
              ),
            ],
          ),

          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _annuaire.isNotEmpty
                ? ListView.builder(itemCount: _annuaire.length, itemBuilder: (context, index) => _buildMemberCard(_annuaire[index], index))
                : Center(
                    child: Text(_message, style: GoogleFonts.poppins(), textAlign: TextAlign.center),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(dynamic member, int index) {
    return Card(
      child: ListTile(
        titleAlignment: ListTileTitleAlignment.top,

        title: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 10,
                children: [
                  Container(
                    height: 40,
                    margin: EdgeInsets.only(top: 00),
                    alignment: Alignment.center,
                    width: 40,
                    decoration: BoxDecoration(color: Color(((index + 1) * 0.1547 * 0xFFFFFF).toInt()).withAlpha(255), shape: BoxShape.circle),
                    child: Text(
                      "${member['prenom'].toString().trim().substring(0, 1).toUpperCase()}${member['nom'].toString().trim().substring(0, 1).toUpperCase()}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "${member['prenom']?.toString().trim().capitalize()} ${member['nom']?.toString().trim().capitalize()}",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 11.0),
                child: Column(
                  children: [
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
            ],
          ),
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
