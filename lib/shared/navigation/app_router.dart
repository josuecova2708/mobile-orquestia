import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/instancia.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/admin/detalle_instancia_screen.dart';
import '../../features/admin/ejecuciones_screen.dart';
import '../../features/admin/empresa_selector_screen.dart';
import '../../features/admin/invitar_admin_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/funcionario/historial_screen.dart';
import '../../features/funcionario/mis_tareas_screen.dart';
import '../../features/funcionario/notificaciones_screen.dart';
import '../../features/tracking/timeline_public_screen.dart';
import '../../features/tracking/tracking_screen.dart';

class AppRouter {
  static GoRouter build(AuthService auth) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final loc = state.matchedLocation;

        // Sin sesión → no puede acceder a zonas privadas
        if ((loc.startsWith('/admin') || loc.startsWith('/funcionario')) && !loggedIn) {
          return '/login';
        }

        // Admin sin empresa seleccionada → ir al selector (excepto si ya está ahí)
        if (loc.startsWith('/admin') &&
            loc != '/admin/selector' &&
            loggedIn &&
            auth.needsEmpresaSelection) {
          return '/admin/selector';
        }

        // Ya logueado intenta ir al login o root → redirigir al dashboard
        if ((loc == '/login' || loc == '/') && loggedIn) {
          if (auth.user!.isAdmin) {
            return auth.needsEmpresaSelection ? '/admin/selector' : '/admin';
          }
          return '/funcionario';
        }

        return null;
      },
      routes: [
        // === PÚBLICO ===
        GoRoute(path: '/', builder: (_, __) => const TrackingScreen()),
        GoRoute(
          path: '/tracking/:id',
          builder: (_, state) {
            final instancia = state.extra as InstanciaPublica;
            return TimelinePublicScreen(instancia: instancia);
          },
        ),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

        // === ADMIN ===
        GoRoute(path: '/admin/selector', builder: (_, __) => const EmpresaSelectorScreen()),
        ShellRoute(
          builder: (context, state, child) => _AdminShell(child: child),
          routes: [
            GoRoute(path: '/admin', builder: (_, __) => const EjecucionesScreen()),
            GoRoute(path: '/admin/invitar', builder: (_, __) => const InvitarAdminScreen()),
            GoRoute(
              path: '/admin/instancia/:id',
              builder: (_, state) {
                final instancia = state.extra as InstanciaProceso;
                return DetalleInstanciaScreen(instancia: instancia);
              },
            ),
          ],
        ),

        // === FUNCIONARIO ===
        ShellRoute(
          builder: (context, state, child) => _FuncionarioShell(child: child),
          routes: [
            GoRoute(path: '/funcionario', builder: (_, __) => const MisTareasScreen()),
            GoRoute(path: '/funcionario/notificaciones', builder: (_, __) => const NotificacionesScreen()),
            GoRoute(path: '/funcionario/historial', builder: (_, __) => const HistorialScreen()),
            GoRoute(
              path: '/funcionario/instancia/:id',
              builder: (_, state) {
                final instancia = state.extra as InstanciaProceso;
                return DetalleInstanciaScreen(instancia: instancia, allowCancel: false);
              },
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _testPush(BuildContext context) async {
  try {
    final res = await ApiClient().dio.post(ApiConstants.testPush);
    final data = res.data as Map<String, dynamic>;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(data['mensaje']?.toString() ?? 'Respuesta recibida'),
      backgroundColor: data['status'] == 'SENT' ? AppColors.completed : AppColors.pending,
      duration: const Duration(seconds: 5),
    ));
  } catch (e) {
    if (!context.mounted) return;
    String msg = 'Error desconocido';
    if (e is DioException && e.response != null) {
      final body = e.response!.data;
      if (body is Map) {
        msg = '${e.response!.statusCode}: ${body['error'] ?? body}';
      } else {
        msg = '${e.response!.statusCode}: $body';
      }
    } else {
      msg = e.toString();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.cancelled,
      duration: const Duration(seconds: 8),
    ));
  }
}

// Shell del Admin (sin bottom nav)
class _AdminShell extends StatelessWidget {
  final Widget child;
  const _AdminShell({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

// Shell del Funcionario con Bottom Navigation + logout
class _FuncionarioShell extends StatelessWidget {
  final Widget child;
  const _FuncionarioShell({required this.child});

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/funcionario/notificaciones')) return 1;
    if (loc.startsWith('/funcionario/historial')) return 2;
    return 0;
  }

  String _title(int idx) {
    switch (idx) {
      case 1: return 'Notificaciones';
      case 2: return 'Mi historial';
      default: return 'Mis tareas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    final auth = context.watch<AuthService>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(idx)),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.border,
              child: Text(
                user != null && user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'F',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                final router = GoRouter.of(context);
                auth.logout().then((_) => router.go('/'));
              } else if (value == 'test_push') {
                await _testPush(context);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nombreCompleto ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'test_push',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.active),
                    SizedBox(width: 10),
                    Text('Probar notificación push'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppColors.cancelled),
                    SizedBox(width: 10),
                    Text('Cerrar sesión', style: TextStyle(color: AppColors.cancelled)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/funcionario');
              case 1: context.go('/funcionario/notificaciones');
              case 2: context.go('/funcionario/historial');
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Mis tareas'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Notificaciones'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
          ],
        ),
      ),
    );
  }
}
