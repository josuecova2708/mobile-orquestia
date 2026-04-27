import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EstadoChip extends StatelessWidget {
  final String estado;
  final bool small;

  const EstadoChip({super.key, required this.estado, this.small = false});

  @override
  Widget build(BuildContext context) {
    final config = _config(estado);
    final fontSize = small ? 11.0 : 12.0;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _EstadoConfig _config(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVA':
      case 'EN_PROGRESO':
        return _EstadoConfig('En progreso', AppColors.active, AppColors.activeLight);
      case 'COMPLETADA':
        return _EstadoConfig('Completada', AppColors.completed, AppColors.completedLight);
      case 'CANCELADA':
      case 'RECHAZADA':
        return _EstadoConfig('Cancelada', AppColors.cancelled, AppColors.cancelledLight);
      case 'ERROR':
        return _EstadoConfig('Error', AppColors.error, AppColors.cancelledLight);
      case 'PENDIENTE':
      default:
        return _EstadoConfig('Pendiente', AppColors.pending, AppColors.pendingLight);
    }
  }
}

class _EstadoConfig {
  final String label;
  final Color color;
  final Color background;
  const _EstadoConfig(this.label, this.color, this.background);
}
