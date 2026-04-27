import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/auth_response.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class EmpresaSelectorScreen extends StatelessWidget {
  const EmpresaSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final empresas = auth.user?.empresasAdmin ?? [];
    final nombre = auth.user?.nombre ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_tree_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Orquestia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Hola, $nombre 👋',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona la empresa que quieres administrar.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              if (empresas.isEmpty)
                _EmptyEmpresas(auth: auth)
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: empresas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _EmpresaCard(
                      empresa: empresas[i],
                      onTap: () async {
                        await auth.selectEmpresa(empresas[i].id);
                        if (!context.mounted) return;
                        context.go('/admin');
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    auth.logout().then((_) => router.go('/'));
                  },
                  icon: const Icon(Icons.logout, size: 16, color: AppColors.textMuted),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmpresaCard extends StatelessWidget {
  final EmpresaResumen empresa;
  final VoidCallback onTap;

  const _EmpresaCard({required this.empresa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.pendingLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.business_outlined, color: AppColors.textSecondary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                empresa.nombre,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyEmpresas extends StatelessWidget {
  final AuthService auth;
  const _EmptyEmpresas({required this.auth});

  @override
  Widget build(BuildContext context) {
    // Sin empresasAdmin pero puede tener empresaId directo
    final directId = auth.user?.empresaId;
    if (directId != null) {
      return ElevatedButton(
        onPressed: () async {
          await auth.selectEmpresa(directId);
          if (!context.mounted) return;
          context.go('/admin');
        },
        child: const Text('Ingresar al dashboard'),
      );
    }
    return const Center(
      child: Text(
        'No tienes empresas asignadas.\nContacta a un administrador.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}
