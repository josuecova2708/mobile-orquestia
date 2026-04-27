import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/instancia.dart';
import '../../core/services/instancia_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/loading_overlay.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _service = InstanciaService();
  List<InstanciaProceso> _instancias = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      _instancias = await _service.miHistorial();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoadingOverlay(
        isLoading: _loading,
        child: _loading
            ? const SizedBox.shrink()
            : _instancias.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.history, size: 56, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text(
                          'Sin historial',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aquí aparecerán los procesos en los que hayas participado.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargar,
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _instancias.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _HistorialCard(
                        instancia: _instancias[i],
                        onTap: () => context.push(
                          '/funcionario/instancia/${_instancias[i].id}',
                          extra: _instancias[i],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  final InstanciaProceso instancia;
  final VoidCallback onTap;

  const _HistorialCard({required this.instancia, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    return GestureDetector(
      onTap: onTap,
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
                const Icon(Icons.play_arrow_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Inicio: ${fmt.format(instancia.fechaInicio)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (instancia.fechaFin != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.stop_circle_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Fin: ${fmt.format(instancia.fechaFin!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
