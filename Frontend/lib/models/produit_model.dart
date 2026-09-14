class ProduitModel {
  final int id;
  final String nom;
  final String? description;
  final String? categorie;
  final double prix;
  final int quantiteDisponible;
  final String? image;
  final String statut;
  final int? agriculteurId;
  final String? agriculteurName;
  final double? agriculteurMoyenneNote;
  final DateTime? createdAt;

  const ProduitModel({
    required this.id,
    required this.nom,
    this.description,
    this.categorie,
    required this.prix,
    required this.quantiteDisponible,
    this.image,
    required this.statut,
    this.agriculteurId,
    this.agriculteurName,
    this.agriculteurMoyenneNote,
    this.createdAt,
  });

  bool get estDisponible => statut == 'disponible';

  String get statutLabel {
    switch (statut) {
      case 'disponible':
        return 'Disponible';
      case 'rupture':
        return 'Rupture de stock';
      case 'archive':
        return 'Archivé';
      default:
        return statut;
    }
  }

  factory ProduitModel.fromJson(Map<String, dynamic> json) {
    final agriculteur = json['agriculteur'] as Map<String, dynamic>?;

    return ProduitModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String?,
      categorie: json['categorie'] as String?,
      prix: (json['prix'] as num?)?.toDouble() ?? 0,
      quantiteDisponible: json['quantite_disponible'] is int
          ? json['quantite_disponible'] as int
          : int.tryParse(json['quantite_disponible'].toString()) ?? 0,
      image: json['image'] as String?,
      statut: json['statut'] as String? ?? 'disponible',
      agriculteurId: agriculteur?['id'] is int ? agriculteur!['id'] as int : null,
      agriculteurName: agriculteur?['name'] as String?,
      agriculteurMoyenneNote: (agriculteur?['moyenne_note'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
