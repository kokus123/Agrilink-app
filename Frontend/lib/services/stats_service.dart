import '../config/api_config.dart';
import 'api_service.dart';

class RevenusSimules {
  final double revenuPotentielStockActuel;
  final double revenuReelEstime;
  final int nombreProduitsActifs;
  final String explication;

  const RevenusSimules({
    required this.revenuPotentielStockActuel,
    required this.revenuReelEstime,
    required this.nombreProduitsActifs,
    required this.explication,
  });

  factory RevenusSimules.fromJson(Map<String, dynamic> json) {
    return RevenusSimules(
      revenuPotentielStockActuel:
          (json['revenu_potentiel_stock_actuel'] as num?)?.toDouble() ?? 0,
      revenuReelEstime: (json['revenu_reel_estime'] as num?)?.toDouble() ?? 0,
      nombreProduitsActifs: json['nombre_produits_actifs'] is int
          ? json['nombre_produits_actifs'] as int
          : int.tryParse(json['nombre_produits_actifs'].toString()) ?? 0,
      explication: json['explication'] as String? ?? '',
    );
  }
}

class PredictionPrix {
  final String categorie;
  final double prixMoyenMarche;
  final double prixMin;
  final double prixMax;
  final String tendance;
  final int echantillon;
  final String note;

  const PredictionPrix({
    required this.categorie,
    required this.prixMoyenMarche,
    required this.prixMin,
    required this.prixMax,
    required this.tendance,
    required this.echantillon,
    required this.note,
  });

  factory PredictionPrix.fromJson(Map<String, dynamic> json) {
    return PredictionPrix(
      categorie: json['categorie'] as String? ?? '',
      prixMoyenMarche: (json['prix_moyen_marche'] as num?)?.toDouble() ?? 0,
      prixMin: (json['prix_min'] as num?)?.toDouble() ?? 0,
      prixMax: (json['prix_max'] as num?)?.toDouble() ?? 0,
      tendance: json['tendance'] as String? ?? 'stable',
      echantillon: json['echantillon'] is int
          ? json['echantillon'] as int
          : int.tryParse(json['echantillon'].toString()) ?? 0,
      note: json['note'] as String? ?? '',
    );
  }
}

class StatsService {
  final ApiService _api = ApiService();

  Future<RevenusSimules> simulerRevenus() async {
    final response = await _api.get(ApiConfig.simulerRevenusUrl, requiresAuth: true);
    return RevenusSimules.fromJson(response);
  }

  Future<PredictionPrix> predictionPrix(String categorie) async {
    final response = await _api.get(
      '${ApiConfig.predictionPrixUrl}?categorie=${Uri.encodeQueryComponent(categorie)}',
      requiresAuth: true,
    );
    return PredictionPrix.fromJson(response);
  }
}
