class BoletimConfig {
  final double notaMinima;
  final double escalaMaxima;
  final String sistemaAvaliacao;
  final String nomenclaturaPeriodo;

  const BoletimConfig({
    this.notaMinima = 10.0,
    this.escalaMaxima = 20.0,
    this.sistemaAvaliacao = '0-20',
    this.nomenclaturaPeriodo = 'Trimestre',
  });

  factory BoletimConfig.fromMap(Map<String, dynamic> m) => BoletimConfig(
        notaMinima: _toDouble(m['nota_minima'], 10.0),
        escalaMaxima: _toDouble(m['escala_maxima'], 20.0),
        sistemaAvaliacao: (m['sistema_avaliacao'] ?? '0-20').toString(),
        nomenclaturaPeriodo:
            (m['nomenclatura_periodo'] ?? 'Trimestre').toString(),
      );

  static double _toDouble(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static const defaults = BoletimConfig();
}

class StudentBoletimData {
  final List<dynamic> terms;
  final List<dynamic> grades;
  final double media;
  final BoletimConfig config;

  const StudentBoletimData({
    required this.terms,
    required this.grades,
    required this.media,
    this.config = BoletimConfig.defaults,
  });
}
