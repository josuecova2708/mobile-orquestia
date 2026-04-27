import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/instancia.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/estado_chip.dart';
import '../../shared/widgets/timeline_stepper.dart';

class TimelinePublicScreen extends StatelessWidget {
  final InstanciaPublica instancia;

  const TimelinePublicScreen({super.key, required this.instancia});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final steps = instancia.timeline.map((t) => TimelineStep(
          label: t.nodoLabel,
          estado: t.estado,
          fecha: t.fechaCompletado,
        )).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado del proceso'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
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
                  EstadoChip(estado: instancia.estado),
                  const SizedBox(height: 12),
                  Text(
                    instancia.nombreProceso,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.calendar_today_outlined, 'Inicio', fmt.format(instancia.fechaInicio)),
                  if (instancia.fechaFin != null) ...[
                    const SizedBox(height: 6),
                    _infoRow(Icons.check_circle_outline, 'Finalizado', fmt.format(instancia.fechaFin!)),
                  ],
                  const SizedBox(height: 6),
                  _infoRow(Icons.tag, 'ID', instancia.id, monospace: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Progreso del proceso',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (steps.isEmpty)
              const Center(
                child: Text(
                  'El proceso aún no tiene pasos registrados.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TimelineStepper(steps: steps),
              ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Los datos del formulario no se muestran por privacidad.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool monospace = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: monospace ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
