import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_constants.dart';
import '../../core/models/tarea_instancia.dart';
import '../../core/services/tarea_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/loading_overlay.dart';

class MisTareasScreen extends StatefulWidget {
  const MisTareasScreen({super.key});

  @override
  State<MisTareasScreen> createState() => _MisTareasScreenState();
}

class _MisTareasScreenState extends State<MisTareasScreen> {
  final _service = TareaService();
  List<TareaInstancia> _tareas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      _tareas = await _service.misTareas();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _abrirWeb() async {
    final uri = Uri.parse(ApiConstants.webUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: _cargar,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh, color: Colors.white, size: 20),
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: _loading
            ? const SizedBox.shrink()
            : _tareas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.task_alt, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes tareas pendientes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cuando te asignen una tarea aparecerá aquí.',
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
                      itemCount: _tareas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _TareaCard(
                        tarea: _tareas[i],
                        onResolverWeb: _abrirWeb,
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _TareaCard extends StatelessWidget {
  final TareaInstancia tarea;
  final VoidCallback onResolverWeb;

  const _TareaCard({required this.tarea, required this.onResolverWeb});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    return Container(
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
                child: Text(
                  tarea.nodoLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              EstadoChip(estado: tarea.estado, small: true),
            ],
          ),
          const SizedBox(height: 8),
          if (tarea.departamentoId.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  tarea.departamentoId,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                'Asignada: ${fmt.format(tarea.fechaCreacion)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Aviso + botón resolver en la web
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.activeLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.active.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.open_in_browser, color: AppColors.active, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Completa esta tarea desde el portal web',
                    style: TextStyle(fontSize: 12, color: AppColors.active, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onResolverWeb,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Resolver en la web'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
