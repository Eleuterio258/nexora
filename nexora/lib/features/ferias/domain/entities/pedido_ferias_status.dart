enum PedidoFeriasStatus {
  pendente('pendente'),
  aprovado('aprovado'),
  rejeitado('rejeitado'),
  cancelado('cancelado'),
  gozada('gozada');

  final String value;

  const PedidoFeriasStatus(this.value);

  static PedidoFeriasStatus fromString(String value) {
    return PedidoFeriasStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PedidoFeriasStatus.pendente,
    );
  }
}
