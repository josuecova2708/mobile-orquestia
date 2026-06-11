import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/tramite_detalle.dart';
import '../../core/services/cliente_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/estado_chip.dart';

class DetalleTramiteScreen extends StatefulWidget {
  final String instanciaId;
  final String tituloInicial;

  const DetalleTramiteScreen({super.key, required this.instanciaId, this.tituloInicial = 'Trámite'});

  @override
  State<DetalleTramiteScreen> createState() => _DetalleTramiteScreenState();
}

class _DetalleTramiteScreenState extends State<DetalleTramiteScreen> {
  final _cliente = ClienteService();
  final _fechaHora = DateFormat('dd/MM/yy HH:mm');

  TramiteDetalle? _detalle;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final d = await _cliente.detalle(widget.instanciaId);
      if (mounted) setState(() { _detalle = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detalle;
    return Scaffold(
      appBar: AppBar(title: Text(d?.procesoNombre ?? widget.tituloInicial)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? const Center(child: Text('No se pudo cargar el trámite.'))
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _header(d),
                      const SizedBox(height: 20),
                      Text('Seguimiento', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (d.tareas.isEmpty)
                        const Text('El trámite aún no tiene pasos registrados.',
                            style: TextStyle(color: AppColors.textSecondary))
                      else
                        ...List.generate(d.tareas.length, (i) => _paso(d.tareas[i], i == d.tareas.length - 1)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _header(TramiteDetalle d) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(d.procesoNombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            EstadoChip(estado: d.estado),
          ]),
          const SizedBox(height: 10),
          Text('Iniciado: ${_fechaHora.format(d.fechaInicio)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          if (d.fechaFin != null)
            Text('Finalizado: ${_fechaHora.format(d.fechaFin!)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _paso(TareaDetalle t, bool ultimo) {
    final color = _colorEstado(t.estado);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Línea + punto
        Column(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(_iconoEstado(t.estado), size: 16, color: color),
          ),
          if (!ultimo) Expanded(child: Container(width: 2, color: AppColors.border)),
        ]),
        const SizedBox(width: 12),
        // Contenido
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.nodoLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text([
                t.estado,
                if (t.ejecutadoPor != null) t.ejecutadoPor!,
                if (t.fechaCompletado != null) _fechaHora.format(t.fechaCompletado!),
              ].join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              if (t.isCompletada && t.datosVisibles.isNotEmpty) ...[
                const SizedBox(height: 8),
                _formulario(t),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _formulario(TareaDetalle t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pendingLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final e in t.datosVisibles) ...[
          Text(e.key.toUpperCase(),
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          _valor(e.value),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }

  Widget _valor(dynamic v) {
    if (v is List && v.isNotEmpty && v.first is List) {
      // GRID
      return Column(
        children: [
          for (final fila in v)
            Row(children: [
              for (final celda in (fila as List))
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    color: AppColors.surface,
                    child: Text('$celda', style: const TextStyle(fontSize: 12)),
                  ),
                ),
            ]),
        ],
      );
    }
    if (v is String && v.startsWith('http')) {
      return const Row(children: [
        Icon(Icons.attach_file, size: 14, color: AppColors.active),
        SizedBox(width: 4),
        Text('Archivo adjunto', style: TextStyle(fontSize: 13, color: AppColors.active)),
      ]);
    }
    String texto;
    if (v is bool) {
      texto = v ? 'Sí' : 'No';
    } else if (v == null || v == '') {
      texto = '—';
    } else {
      texto = '$v';
    }
    return Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500));
  }

  Color _colorEstado(String e) {
    switch (e) {
      case 'COMPLETADA': return AppColors.completed;
      case 'EN_PROGRESO': return AppColors.active;
      case 'RECHAZADA': return AppColors.cancelled;
      default: return AppColors.pending;
    }
  }

  IconData _iconoEstado(String e) {
    switch (e) {
      case 'COMPLETADA': return Icons.check;
      case 'EN_PROGRESO': return Icons.autorenew;
      case 'RECHAZADA': return Icons.close;
      default: return Icons.circle_outlined;
    }
  }
}
