class ProduitLigneLivraison {
  final String nom;
  final int quantite;

  const ProduitLigneLivraison({required this.nom, required this.quantite});

  factory ProduitLigneLivraison.fromJson(Map<String, dynamic> json) {
    return ProduitLigneLivraison(
      nom: json['nom'] as String? ?? '',
      quantite: json['quantite'] is int
          ? json['quantite'] as int
          : int.tryParse(json['quantite'].toString()) ?? 0,
    );
  }
}

/// Convertit une valeur JSON en double, qu'elle arrive en nombre (JSON
/// natif) ou en texte (colonnes MySQL DECIMAL, comme latitude/longitude
/// et montant_total, sérialisées en chaîne par défaut par Eloquent).
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class AcheteurLivraison {
  final int id;
  final String name;
  final String? phone;
  final double? latitude;
  final double? longitude;

  const AcheteurLivraison({
    required this.id,
    required this.name,
    this.phone,
    this.latitude,
    this.longitude,
  });

  bool get aPartagePosition => latitude != null && longitude != null;

  factory AcheteurLivraison.fromJson(Map<String, dynamic> json) {
    return AcheteurLivraison(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }
}

class CommandeLivraison {
  final int id;
  final double montantTotal;
  final AcheteurLivraison acheteur;
  final List<ProduitLigneLivraison> produits;

  const CommandeLivraison({
    required this.id,
    required this.montantTotal,
    required this.acheteur,
    required this.produits,
  });

  factory CommandeLivraison.fromJson(Map<String, dynamic> json) {
    final produitsJson = (json['produits'] as List?) ?? [];
    return CommandeLivraison(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      montantTotal: _toDouble(json['montant_total']) ?? 0,
      acheteur: AcheteurLivraison.fromJson(json['acheteur'] as Map<String, dynamic>),
      produits: produitsJson
          .map((e) => ProduitLigneLivraison.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LivraisonModel {
  final int id;
  final String statut;
  final double? latitudeActuelle;
  final double? longitudeActuelle;
  final DateTime? dateLivraisonPrevue;
  final DateTime? dateLivraisonReelle;
  final CommandeLivraison commande;

  const LivraisonModel({
    required this.id,
    required this.statut,
    this.latitudeActuelle,
    this.longitudeActuelle,
    this.dateLivraisonPrevue,
    this.dateLivraisonReelle,
    required this.commande,
  });

  String get statutLabel {
    switch (statut) {
      case 'proposee':
        return 'Proposée';
      case 'en_attente':
        return 'En attente';
      case 'en_cours':
        return 'En cours';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }

  factory LivraisonModel.fromJson(Map<String, dynamic> json) {
    return LivraisonModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      statut: json['statut'] as String? ?? 'en_attente',
      latitudeActuelle: _toDouble(json['latitude_actuelle']),
      longitudeActuelle: _toDouble(json['longitude_actuelle']),
      dateLivraisonPrevue: json['date_livraison_prevue'] != null
          ? DateTime.tryParse(json['date_livraison_prevue'].toString())
          : null,
      dateLivraisonReelle: json['date_livraison_reelle'] != null
          ? DateTime.tryParse(json['date_livraison_reelle'].toString())
          : null,
      commande: CommandeLivraison.fromJson(json['commande'] as Map<String, dynamic>),
    );
  }
}
