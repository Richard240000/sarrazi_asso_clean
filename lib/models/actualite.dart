class Actualite {
  final int id;
  final String texte;
  final String? nature; // Nouveau champ optionnel
  final String? nom;    // Nouveau champ optionnel
  final DateTime dateAjout;

  Actualite({
    required this.id,
    required this.texte,
    this.nature,
    this.nom,
    required this.dateAjout,
  });

  factory Actualite.fromJson(Map<String, dynamic> json) {
    return Actualite(
      id: json['id'] ?? 0, // Ajout de la gestion de l'ID
      texte: json['texte'],
      nature: json['nature'], // Nouveau champ
      nom: json['nom'],       // Nouveau champ
      dateAjout: DateTime.parse(json['date_ajout']),
    );
  }
}

