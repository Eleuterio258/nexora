import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/module_access_model.dart';

class ModulosPage extends StatelessWidget {
  final List<ModuleAccessModel> modules;

  const ModulosPage({super.key, required this.modules});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Módulos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: modules.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Text(
                      'Sem módulos atribuídos.\nContacte o administrador para obter acesso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: modules.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final module = modules[index];
                    return InkWell(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${module.module} em breve')),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.apps_outlined,
                              size: 22,
                              color: AppColors.brandAccent,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module.module,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (module.actions.isNotEmpty)
                                    Text(
                                      module.actions.join(', '),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
