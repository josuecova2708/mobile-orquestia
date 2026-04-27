import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class TimelineStep {
  final String label;
  final String estado;
  final DateTime? fecha;
  final String? extra;

  const TimelineStep({
    required this.label,
    required this.estado,
    this.fecha,
    this.extra,
  });
}

class TimelineStepper extends StatelessWidget {
  final List<TimelineStep> steps;

  const TimelineStepper({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return _StepRow(step: step, isLast: isLast);
      }),
    );
  }
}

class _StepRow extends StatelessWidget {
  final TimelineStep step;
  final bool isLast;

  const _StepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = _color(step.estado);
    final isCompleted = step.estado == 'COMPLETADA';
    final isActive = step.estado == 'EN_PROGRESO' || step.estado == 'ACTIVA';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                _StepIcon(isCompleted: isCompleted, isActive: isActive, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? AppColors.completed : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isActive ? AppColors.active : AppColors.textPrimary,
                    ),
                  ),
                  if (step.extra != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.extra!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  if (step.fecha != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(step.fecha!),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _color(String estado) {
    switch (estado.toUpperCase()) {
      case 'COMPLETADA':
        return AppColors.completed;
      case 'EN_PROGRESO':
      case 'ACTIVA':
        return AppColors.active;
      case 'RECHAZADA':
      case 'CANCELADA':
        return AppColors.cancelled;
      default:
        return AppColors.border;
    }
  }
}

class _StepIcon extends StatefulWidget {
  final bool isCompleted;
  final bool isActive;
  final Color color;

  const _StepIcon({required this.isCompleted, required this.isActive, required this.color});

  @override
  State<_StepIcon> createState() => _StepIconState();
}

class _StepIconState extends State<_StepIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: AppColors.completed, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    if (widget.isActive) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.active.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.radio_button_checked, size: 14, color: Colors.white),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 2),
      ),
    );
  }
}
