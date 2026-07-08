import 'package:flutter/material.dart';

/// Chave global do Navigator — permite navegar (ex.: a partir de um deep
/// link recebido) sem depender do BuildContext de um widget específico.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
