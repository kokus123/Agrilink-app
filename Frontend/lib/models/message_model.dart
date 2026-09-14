class MessageModel {
  final int id;
  final int livraisonId;
  final int expediteurId;
  final String expediteurRole;
  final String contenu;
  final bool lu;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.livraisonId,
    required this.expediteurId,
    required this.expediteurRole,
    required this.contenu,
    required this.lu,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      livraisonId: json['livraison_id'] is int
          ? json['livraison_id'] as int
          : int.parse(json['livraison_id'].toString()),
      expediteurId: json['expediteur_id'] is int
          ? json['expediteur_id'] as int
          : int.parse(json['expediteur_id'].toString()),
      expediteurRole: json['expediteur_role'] as String? ?? '',
      contenu: json['contenu'] as String? ?? '',
      lu: json['lu'] is bool ? json['lu'] as bool : (json['lu'] == 1 || json['lu'] == '1'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
