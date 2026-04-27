import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/instancia.dart';
import '../../core/models/tarea_instancia.dart';
import '../../core/services/instancia_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/timeline_stepper.dart';

class DetalleInstanciaScreen extends StatefulWidget {
  final InstanciaProceso instancia;
  final bool allowCancel;

  const DetalleInstanciaScreen({
    super.key,
    required this.instancia,
    this.allowCancel = true,
  });

  @override
  State<DetalleInstanciaScreen> createState() => _DetalleInstanciaScreenState();
}

class _DetalleInstanciaScreenState extends State<DetalleInstanciaScreen> {
  final _service = InstanciaService();
  List<TareaInstancia> _tareas = [];
  bool _loading = true;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    setState(() => _loading = true);
    try {
      _tareas = await _service.obtenerTareas(widget.instancia.id);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cancelar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar proceso'),
        content: const Text('¿Estás seguro de que deseas cancelar este proceso? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.cancelled),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await _service.cancelarInstancia(widget.instancia.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proceso cancelado'), backgroundColor: AppColors.completed),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cancelar el proceso'), backgroundColor: AppColors.cancelled),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final steps = _tareas.map((t) => TimelineStep(
          label: t.nodoLabel,
          estado: t.estado,
          fecha: t.fechaCompletado,
          extra: t.departamentoId.isNotEmpty ? 'Depto: ${t.departamentoId}' : null,
        )).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de instancia'),
      ),
      body: LoadingOverlay(
        isLoading: _loading || _cancelling,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EstadoChip(estado: widget.instancia.estado),
                    const SizedBox(height: 12),
                    Text(
                      widget.instancia.displayNombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${widget.instancia.id}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    _row(Icons.person_outline, 'Iniciado por', widget.instancia.displayCreadoPor),
                    const SizedBox(height: 6),
                    _row(Icons.calendar_today_outlined, 'Inicio', fmt.format(widget.instancia.fechaInicio)),
                    if (widget.instancia.fechaFin != null) ...[
                      const SizedBox(height: 6),
                      _row(Icons.check_circle_outline, 'Fin', fmt.format(widget.instancia.fechaFin!)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _cargarTareas,
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (steps.isEmpty && !_loading)
                const Center(
                  child: Text('Sin tareas', style: TextStyle(color: AppColors.textSecondary)),
                )
              else if (steps.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TimelineStepper(steps: steps),
                ),
              if (widget.instancia.isActiva && widget.allowCancel) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _cancelling ? null : _cancelar,
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.cancelled),
                  label: const Text('Cancelar proceso', style: TextStyle(color: AppColors.cancelled)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cancelled),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
