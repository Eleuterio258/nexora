import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/ferias_bloc.dart';
import '../bloc/ferias_event.dart';
import '../bloc/ferias_state.dart';
import '../widgets/pedido_ferias_tile.dart';
import 'novo_pedido_ferias_page.dart';

class FeriasPage extends StatelessWidget {
  const FeriasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FeriasBloc>()..add(const LoadMeusPedidosFerias()),
      child: const _FeriasView(),
    );
  }
}

class _FeriasView extends StatelessWidget {
  const _FeriasView();

  Future<void> _novoPedido(BuildContext context) async {
    final bloc = context.read<FeriasBloc>();
    final criado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NovoPedidoFeriasPage()),
    );
    if (criado == true) {
      bloc.add(const LoadMeusPedidosFerias());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<FeriasBloc, FeriasState>(
        listener: (context, state) {
          if (state is FeriasFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is PedidoFeriasCancelado) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pedido cancelado.')),
            );
            context.read<FeriasBloc>().add(const LoadMeusPedidosFerias());
          }
        },
        builder: (context, state) {
          if (state is FeriasLoading || state is FeriasInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = state is MeusPedidosFeriasLoaded ? state.pedidos : [];

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<FeriasBloc>().add(const LoadMeusPedidosFerias()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Meus pedidos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _novoPedido(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Pedir férias'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pedidos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Ainda não tens pedidos de férias ou ausência.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...pedidos.map(
                    (p) => PedidoFeriasTile(
                      pedido: p,
                      onCancelar: () => context
                          .read<FeriasBloc>()
                          .add(CancelarPedidoFerias(id: p.id)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
