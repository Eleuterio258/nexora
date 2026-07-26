class NotificationModel {
  final int id;
  final String tipo;
  final String titulo;
  final String corpo;
  final bool lida;
  final Map<String, dynamic>? dados;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.lida,
    this.dados,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      corpo: json['corpo'] as String,
      lida: json['lida'] as bool? ?? false,
      dados: json['dados'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? tipo,
    String? titulo,
    String? corpo,
    bool? lida,
    Map<String, dynamic>? dados,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      corpo: corpo ?? this.corpo,
      lida: lida ?? this.lida,
      dados: dados ?? this.dados,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
