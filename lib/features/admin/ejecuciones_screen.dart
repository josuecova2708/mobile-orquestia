import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_constants.dart';
import '../../core/models/instancia.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/instancia_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/loading_overlay.dart';

Future<void> _testPushAdmin(BuildContext context) async {
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

class EjecucionesScreen extends StatefulWidget {
  const EjecucionesScreen({super.key});

  @override
  State<EjecucionesScreen> createState() => _EjecucionesScreenState();
}

class _EjecucionesScreenState extends State<EjecucionesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _service = InstanciaService();
  List<InstanciaProceso> _activas = [];
  List<InstanciaProceso> _historial = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      final empresaId = auth.selectedEmpresaId ?? auth.user?.empresaId ?? '';
      final todas = await _service.listarInstancias(empresaId);
      setState(() {
        _activas = todas.where((i) => i.estado == 'ACTIVA').toList();
        _historial = todas.where((i) => i.estado != 'ACTIVA').toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejecuciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Invitar co-admin',
            onPressed: () => context.push('/admin/invitar'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final auth = context.read<AuthService>();
              final router = GoRouter.of(context);
              if (value == 'cambiar_empresa') {
                await auth.selectEmpresa('');
                if (!mounted) return;
                router.go('/admin/selector');
              } else if (value == 'test_push') {
                await _testPushAdmin(context);
              } else if (value == 'logout') {
                auth.logout().then((_) => router.go('/'));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'cambiar_empresa',
                child: Row(children: [
                  Icon(Icons.business_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Cambiar empresa'),
                ]),
              ),
              const PopupMenuItem(
                value: 'test_push',
                child: Row(children: [
                  Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.active),
                  SizedBox(width: 10),
                  Text('Probar notificación push'),
                ]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout, size: 18, color: AppColors.cancelled),
                  SizedBox(width: 10),
                  Text('Cerrar sesión', style: TextStyle(color: AppColors.cancelled)),
                ]),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline, size: 16),
                  const SizedBox(width: 6),
                  Text('Activas (${_activas.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 16),
                  const SizedBox(width: 6),
                  Text('Historial (${_historial.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: TabBarView(
          controller: _tab,
          children: [
            _Lista(
              instancias: _activas,
              onRefresh: _cargar,
              emptyIcon: Icons.inbox_outlined,
              emptyTitle: 'No hay procesos activos',
            ),
            _Lista(
              instancias: _historial,
              onRefresh: _cargar,
              emptyIcon: Icons.history_outlined,
              emptyTitle: 'No hay procesos en historial',
            ),
          ],
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  final List<InstanciaProceso> instancias;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;
  final String emptyTitle;

  const _Lista({
    required this.instancias,
    required this.onRefresh,
    required this.emptyIcon,
    required this.emptyTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (instancias.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(emptyTitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: instancias.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _InstanciaCard(instancia: instancias[i]),
      ),
    );
  }
}

class _InstanciaCard extends StatelessWidget {
  final InstanciaProceso instancia;
  const _InstanciaCard({required this.instancia});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    return GestureDetector(
      onTap: () => context.push('/admin/instancia/${instancia.id}', extra: instancia),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instancia.displayNombre,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        instancia.id,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                EstadoChip(estado: instancia.estado, small: true),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    instancia.displayCreadoPor,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  fmt.format(instancia.fechaInicio),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
