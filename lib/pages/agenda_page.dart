import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:sarrazi_asso_clean/pages/base_page.dart';
import 'package:sarrazi_asso_clean/services/http_service.dart';
import 'package:sarrazi_asso_clean/services/popup_service.dart';

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
    chargerAgenda();
  }

  Future<void> chargerAgenda() async {
    final response = await HttpService.chargerAgenda();

    if (response.isSuccess) {
      setState(() {
        evenements = response.data;
        evenements = evenements.toList().sortedBy((x) => DateTime.tryParse((x['date_event'] ?? '').toString()) ?? DateTime.now());
      });
    } else {
      if (!mounted) return;
      PopupService.showErrorMessage(context, response.data?.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(title: "Agenda des événements", body: getBody(), message: "Si vous souhaitez ajouter un événement, n'hésitez pas à nous contacter !", withContact: true);
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
              var date = DateTime.tryParse((evt['date_event'] ?? '').toString()) ?? DateTime.now();
              var color = Color(((index + 1) * 0.1547 * 0xFFFFFF).toInt()).withAlpha(255);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
                child: Row(
                  spacing: 20,
                  children: [
                    Column(
                      children: [
                        Text(
                          "${DateFormat("E", 'fr').format(date)}",
                          style: TextStyle(color: color, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          height: 40,
                          width: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          child: Text("${date.day}", style: TextStyle(color: Colors.white)),
                        ),
                        Text(
                          "${DateFormat("MMM", 'fr').format(date)}",
                          style: TextStyle(color: color, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "${DateFormat("yy", 'fr').format(date)}",
                          style: TextStyle(color: color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Card(
                        child: ListTile(
                          titleAlignment: ListTileTitleAlignment.top,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),

                          title: Text(
                            evt['titre'],
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: color),
                          ),

                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Column(
                              spacing: 5,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  spacing: 5,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Symbols.calendar_check, size: 20, color: color, weight: 600),
                                    Expanded(child: Text("Le ${DateFormat("dd/MM/yyyy à HH:mm").format(date)}")),
                                  ],
                                ),
                                Row(
                                  spacing: 5,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Symbols.location_on, size: 20, color: color, weight: 600),
                                    Expanded(child: Text(evt['lieu'] ?? 'Lieu non précisé')),
                                  ],
                                ),
                                Row(
                                  spacing: 5,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Symbols.description, size: 20, color: color, weight: 600),
                                    Expanded(child: Text(evt['description'] ?? '')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
