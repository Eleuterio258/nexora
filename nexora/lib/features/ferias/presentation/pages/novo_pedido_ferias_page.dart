import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/tipo_ausencia_entity.dart';
import '../bloc/ferias_bloc.dart';
import '../bloc/ferias_event.dart';
import '../bloc/ferias_state.dart';

class NovoPedidoFeriasPage extends StatelessWidget {
  const NovoPedidoFeriasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FeriasBloc>()..add(const LoadTiposAusencia()),
      child: const _NovoPedidoFeriasView(),
    );
  }
}

class _NovoPedidoFeriasView extends StatefulWidget {
  const _NovoPedidoFeriasView();

  @override
  State<_NovoPedidoFeriasView> createState() => _NovoPedidoFeriasViewState();
}

class _NovoPedidoFeriasViewState extends State<_NovoPedidoFeriasView> {
  final _motivoController = TextEditingController();
  TipoAusenciaEntity? _tipoSelecionado;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData({required bool inicio}) async {
    final now = DateTime.now();
    final initialDate = inicio
        ? (_dataInicio ?? now)
        : (_dataFim ?? _dataInicio ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;

    setState(() {
      if (inicio) {
        _dataInicio = picked;
        if (_dataFim != null && _dataFim!.isBefore(picked)) {
          _dataFim = picked;
        }
      } else {
        _dataFim = picked;
      }
    });
  }

  void _submeter(BuildContext context) {
    final tipo = _tipoSelecionado;
    final inicio = _dataInicio;
    final fim = _dataFim;

    if (tipo == null || inicio == null || fim == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preenche o tipo e o período do pedido.')),
      );
      return;
    }

    context.read<FeriasBloc>().add(
          CriarPedidoFerias(
            tipoId: tipo.id,
            dataInicio: inicio,
            dataFim: fim,
            motivo: _motivoController.text.trim().isEmpty
                ? null
                : _motivoController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Pedir férias')),
      body: BlocConsumer<FeriasBloc, FeriasState>(
        listener: (context, state) {
          if (state is FeriasFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is PedidoFeriasCriado) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pedido submetido com sucesso.')),
            );
            Navigator.of(context).pop(true);
          } else if (state is TiposAusenciaLoaded &&
              _tipoSelecionado == null &&
              state.tipos.isNotEmpty) {
            _tipoSelecionado = state.tipos.first;
          }
        },
        builder: (context, state) {
          final tipos = state is TiposAusenciaLoaded ? state.tipos : <TipoAusenciaEntity>[];
          final loading = state is FeriasLoading && tipos.isEmpty;

          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Tipo de ausência',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<TipoAusenciaEntity>(
                initialValue: _tipoSelecionado ?? (tipos.isNotEmpty ? tipos.first : null),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: tipos
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.nome)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _tipoSelecionado = value),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Data início',
                      value: _dataInicio != null ? formatter.format(_dataInicio!) : null,
                      onTap: () => _selecionarData(inicio: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Data fim',
                      value: _dataFim != null ? formatter.format(_dataFim!) : null,
                      onTap: () => _selecionarData(inicio: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Motivo (opcional)',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _motivoController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state is FeriasLoading ? null : () => _submeter(context),
                child: state is FeriasLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submeter pedido'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value ?? 'Selecionar',
          style: TextStyle(
            color: value != null ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
