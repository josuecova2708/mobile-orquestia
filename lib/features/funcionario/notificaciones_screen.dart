import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/notificacion.dart';
import '../../core/services/notificacion_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/loading_overlay.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  final _service = NotificacionService();
  List<Notificacion> _notifs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      _notifs = await _service.listar();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _marcarLeida(Notificacion n) async {
    if (n.leida) return;
    await _service.marcarLeida(n.id);
    setState(() {
      final idx = _notifs.indexWhere((x) => x.id == n.id);
      if (idx != -1) _notifs[idx] = n.copyWith(leida: true);
    });
  }

  Future<void> _marcarTodas() async {
    await _service.marcarTodasLeidas();
    setState(() {
      _notifs = _notifs.map((n) => n.copyWith(leida: true)).toList();
    });
  }

  int get _noLeidas => _notifs.where((n) => !n.leida).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _noLeidas > 0
          ? FloatingActionButton.extended(
              onPressed: _marcarTodas,
              backgroundColor: AppColors.primary,
              label: const Text('Leer todas', style: TextStyle(color: Colors.white, fontSize: 13)),
              icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            )
          : null,
      body: LoadingOverlay(
        isLoading: _loading,
        child: _loading
            ? const SizedBox.shrink()
            : _notifs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.notifications_none, size: 56, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Sin notificaciones',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    color: AppColors.primary,
                    child: ListView.separated(
                      itemCount: _notifs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) => _NotifTile(
                        notif: _notifs[i],
                        onTap: () => _marcarLeida(_notifs[i]),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Notificacion notif;
  final VoidCallback onTap;

  const _NotifTile({required this.notif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notif.leida ? null : AppColors.activeLight.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: notif.leida ? AppColors.pendingLight : AppColors.activeLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _icon(notif.tipo),
                size: 20,
                color: notif.leida ? AppColors.textMuted : AppColors.active,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.mensaje,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notif.leida ? FontWeight.w400 : FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(notif.fecha),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (!notif.leida)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, left: 8),
                decoration: const BoxDecoration(color: AppColors.active, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String tipo) {
    switch (tipo) {
      case 'TAREA_ASIGNADA':
        return Icons.assignment_outlined;
      case 'DEPT_INVITACION':
        return Icons.group_add_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
