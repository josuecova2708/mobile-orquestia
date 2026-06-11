import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/models/instancia.dart';
import '../../core/models/tarea_instancia.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cliente_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/completar_tarea_screen.dart';
import '../../shared/widgets/estado_chip.dart';

class MisTramitesScreen extends StatefulWidget {
  const MisTramitesScreen({super.key});

  @override
  State<MisTramitesScreen> createState() => _MisTramitesScreenState();
}

class _MisTramitesScreenState extends State<MisTramitesScreen> {
  final _cliente = ClienteService();
  final _fecha = DateFormat('dd/MM/yyyy');

  List<InstanciaProceso> _tramites = [];
  List<TareaInstancia> _acciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_cliente.misTramites(), _cliente.misAcciones()]);
      if (!mounted) return;
      setState(() {
        _tramites = results[0] as List<InstanciaProceso>;
        _acciones = results[1] as List<TareaInstancia>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirAccion(TareaInstancia accion) async {
    final empresaId = context.read<AuthService>().user?.empresaId ?? '';
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => CompletarTareaScreen(
        titulo: accion.nodoLabel,
        campos: accion.formularioCampos,
        empresaId: empresaId,
        instanciaId: accion.instanciaId,
        tareaId: accion.id,
        onSubmit: (datos, comentario) => _cliente.completarAccion(accion.id, datos, comentario),
      ),
    ));
    if (ok == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acción completada'), backgroundColor: AppColors.completed),
        );
      }
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/cliente/recepcion');
          _cargar();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo trámite', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
      onRefresh: _cargar,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_acciones.isNotEmpty) ...[
                  _seccionAcciones(),
                  const SizedBox(height: 8),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Mis trámites', style: Theme.of(context).textTheme.titleMedium),
                ),
                if (_tramites.isEmpty)
                  _vacio()
                else
                  ..._tramites.map(_cardTramite),
                const SizedBox(height: 24),
              ],
            ),
      ),
    );
  }

  Widget _seccionAcciones() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.activeLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.active.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.active, size: 20),
          const SizedBox(width: 8),
          Text('Tienes ${_acciones.length} acción${_acciones.length != 1 ? 'es' : ''} pendiente${_acciones.length != 1 ? 's' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.active)),
        ]),
        const SizedBox(height: 10),
        ..._acciones.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: const Icon(Icons.assignment_ind_outlined),
                  title: Text(a.nodoLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirAccion(a),
                ),
              ),
            )),
      ]),
    );
  }

  Widget _cardTramite(InstanciaProceso t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/cliente/tramite/${t.id}', extra: t),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(t.displayNombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
              EstadoChip(estado: t.estado, small: true),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.event_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('Iniciado ${_fecha.format(t.fechaInicio)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Spacer(),
              const Text('Ver seguimiento', style: TextStyle(fontSize: 12, color: AppColors.active)),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.active),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _vacio() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('No tienes trámites aún.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          const Text('Inicia un trámite desde la web de tu empresa.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
      );
}
