class NotationRecue {
  final int id;
  final int note;
  final String? commentaire;
  final String? acheteurNom;
  final DateTime? createdAt;

  const NotationRecue({
    required this.id,
    required this.note,
    this.commentaire,
    this.acheteurNom,
    this.createdAt,
  });

  factory NotationRecue.fromJson(Map<String, dynamic> json) {
    final acheteur = json['acheteur'] as Map<String, dynamic>?;
    return NotationRecue(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      note: json['note'] is int ? json['note'] as int : int.tryParse(json['note'].toString()) ?? 0,
      commentaire: json['commentaire'] as String?,
      acheteurNom: acheteur?['name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
