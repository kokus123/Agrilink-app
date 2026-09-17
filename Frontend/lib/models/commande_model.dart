class LigneProduitCommande {
  final int id;
  final String nom;
  final int quantite;
  final String? unite;
  final double prixUnitaire;
  final int? agriculteurId;
  final String? agriculteurNom;

  const LigneProduitCommande({
    required this.id,
    required this.nom,
    required this.quantite,
    this.unite,
    required this.prixUnitaire,
    this.agriculteurId,
    this.agriculteurNom,
  });

  double get sousTotal => prixUnitaire * quantite;

  /// Affichage combiné, ex: "2 Cageots" — retombe sur le nombre seul si
  /// l'unité n'est pas connue (anciennes commandes).
  String get quantiteAffichee =>
      (unite != null && unite!.isNotEmpty) ? '$quantite $unite' : '$quantite';

  factory LigneProduitCommande.fromJson(Map<String, dynamic> json) {
    return LigneProduitCommande(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      nom: json['nom'] as String? ?? '',
      quantite: json['quantite'] is int
          ? json['quantite'] as int
          : int.tryParse(json['quantite'].toString()) ?? 0,
      unite: json['unite'] as String?,
      prixUnitaire: (json['prix_unitaire'] as num?)?.toDouble() ?? 0,
      agriculteurId: json['agriculteur_id'] != null
          ? (json['agriculteur_id'] is int
              ? json['agriculteur_id'] as int
              : int.tryParse(json['agriculteur_id'].toString()))
          : null,
      agriculteurNom: json['agriculteur_nom'] as String?,
    );
  }
}

class LivraisonResume {
  final int id;
  final String statut;
  final String? transporteurNom;
  final String? transporteurTelephone;
  final DateTime? dateLivraisonPrevue;

  const LivraisonResume({
    required this.id,
    required this.statut,
    this.transporteurNom,
    this.transporteurTelephone,
    this.dateLivraisonPrevue,
  });

  factory LivraisonResume.fromJson(Map<String, dynamic> json) {
    return LivraisonResume(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      statut: json['statut'] as String? ?? 'en_attente',
      transporteurNom: json['transporteur'] as String?,
      transporteurTelephone: json['transporteur_telephone'] as String?,
      dateLivraisonPrevue: json['date_livraison_prevue'] != null
          ? DateTime.tryParse(json['date_livraison_prevue'].toString())
          : null,
    );
  }
}

class AcheteurResume {
  final int id;
  final String name;
  final String? phone;

  const AcheteurResume({required this.id, required this.name, this.phone});

  factory AcheteurResume.fromJson(Map<String, dynamic> json) {
    return AcheteurResume(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

class AgriculteurACommandeNoter {
  final int id;
  final String nom;

  const AgriculteurACommandeNoter({required this.id, required this.nom});
}

class CommandeModel {
  final int id;
  final double montantTotal;
  final String statut;
  final List<LigneProduitCommande> produits;
  final LivraisonResume? livraison;
  final AcheteurResume? acheteur;
  final DateTime? createdAt;

  const CommandeModel({
    required this.id,
    required this.montantTotal,
    required this.statut,
    required this.produits,
    this.livraison,
    this.acheteur,
    this.createdAt,
  });

  double get totalProduitsListes =>
      produits.fold(0.0, (somme, ligne) => somme + ligne.sousTotal);

  bool get peutNotifierTransporteur => statut == 'en_attente' && livraison == null;

  /// Modifiable/annulable uniquement tant qu'elle est en_attente (côté serveur
  /// aussi vérifié — ceci ne fait que piloter l'affichage des boutons).
  bool get peutEtreModifiee => statut == 'en_attente';

  List<AgriculteurACommandeNoter> get agriculteursDistincts {
    final vus = <int>{};
    final resultat = <AgriculteurACommandeNoter>[];
    for (final ligne in produits) {
      if (ligne.agriculteurId != null && !vus.contains(ligne.agriculteurId)) {
        vus.add(ligne.agriculteurId!);
        resultat.add(AgriculteurACommandeNoter(
          id: ligne.agriculteurId!,
          nom: ligne.agriculteurNom ?? 'Agriculteur',
        ));
      }
    }
    return resultat;
  }

  String get statutLabel {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'confirmee':
        return 'Confirmée';
      case 'en_livraison':
        return 'En livraison';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    final produitsJson = (json['produits'] as List?) ?? [];

    return CommandeModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      montantTotal: (json['montant_total'] as num?)?.toDouble() ?? 0,
      statut: json['statut'] as String? ?? 'en_attente',
      produits: produitsJson
          .map((e) => LigneProduitCommande.fromJson(e as Map<String, dynamic>))
          .toList(),
      livraison: json['livraison'] != null
          ? LivraisonResume.fromJson(json['livraison'] as Map<String, dynamic>)
          : null,
      acheteur: json['acheteur'] != null
          ? AcheteurResume.fromJson(json['acheteur'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
