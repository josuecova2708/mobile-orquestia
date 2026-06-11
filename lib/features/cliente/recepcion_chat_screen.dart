import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/models/proceso_publico.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/documento_service.dart';
import '../../core/services/recepcion_service.dart';
import '../../core/theme/app_theme.dart';

const _imageExts = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
const _videoExts = ['.mp4', '.webm', '.mov'];

class _SlotDoc {
  String? documentoId;
  String? nombreArchivo;
  bool subiendo;
  String? error;
  _SlotDoc({this.documentoId, this.nombreArchivo, this.subiendo = false, this.error});
}

class RecepcionChatScreen extends StatefulWidget {
  const RecepcionChatScreen({super.key});

  @override
  State<RecepcionChatScreen> createState() => _RecepcionChatScreenState();
}

class _RecepcionChatScreenState extends State<RecepcionChatScreen> {
  final _recepcion = RecepcionService();
  final _docService = DocumentoService();
  final _entradaCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<ProcesoPublico> _procesos = [];
  final List<ChatMensaje> _mensajes = [];
  bool _cargando = true;
  bool _pensando = false;

  List<OpcionProceso> _opciones = [];
  ProcesoPublico? _recomendado;

  ProcesoPublico? _seleccionado;
  final Map<int, _SlotDoc> _slots = {};
  bool _iniciando = false;
  String? _errorInicio;

  @override
  void initState() {
    super.initState();
    _mensajes.add(ChatMensaje('agente',
        '¡Hola! Soy tu asistente de recepción. Cuéntame qué necesitas y te llevo al trámite correcto. También puedes elegirlo de la lista.'));
    _cargar();
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final empresaId = context.read<AuthService>().user?.empresaId ?? '';
    try {
      _procesos = await _recepcion.procesosPublicos(empresaId);
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  // ── Chat ────────────────────────────────────────────────────────────────────

  void _enviar() {
    final texto = _entradaCtrl.text.trim();
    if (texto.isEmpty || _pensando) return;
    setState(() {
      _mensajes.add(ChatMensaje('usuario', texto));
      _entradaCtrl.clear();
      _opciones = [];
      _recomendado = null;
    });
    _scrollAbajo();
    _consultar();
  }

  Future<void> _consultar() async {
    final i = _mensajes.indexWhere((m) => m.rol == 'usuario');
    if (i == -1) return;
    final historial = _mensajes.sublist(i);

    setState(() => _pensando = true);
    try {
      final r = await _recepcion.clasificar(historial, _procesos);
      setState(() {
        _pensando = false;
        _mensajes.add(ChatMensaje('agente', r.respuesta));
        _opciones = r.opciones;
        _recomendado = r.procesoRecomendadoId != null ? _buscarProceso(r.procesoRecomendadoId!) : null;
      });
    } catch (_) {
      setState(() {
        _pensando = false;
        _mensajes.add(ChatMensaje('agente',
            'Disculpa, tuve un problema para procesar tu mensaje. ¿Puedes intentarlo de nuevo?'));
      });
    }
    _scrollAbajo();
  }

  void _scrollAbajo() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  // ── Selección + documentos ──────────────────────────────────────────────────

  void _seleccionar(ProcesoPublico p) {
    setState(() {
      _seleccionado = p;
      _slots.clear();
      _errorInicio = null;
    });
  }

  void _seleccionarPorId(String id) {
    final p = _buscarProceso(id);
    if (p != null) _seleccionar(p);
  }

  ProcesoPublico? _buscarProceso(String id) {
    for (final p in _procesos) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool get _puedeIniciar {
    final reqs = _seleccionado?.documentosRequeridos ?? [];
    for (var i = 0; i < reqs.length; i++) {
      if (reqs[i].obligatorio && _slots[i]?.documentoId == null) return false;
    }
    return true;
  }

  Future<void> _iniciar() async {
    final p = _seleccionado;
    if (p == null || !_puedeIniciar || _iniciando) return;
    final ids = _slots.values.map((s) => s.documentoId).whereType<String>().toList();
    setState(() { _iniciando = true; _errorInicio = null; });
    try {
      await _recepcion.iniciarTramite(p.id, ids);
      if (mounted) context.go('/cliente');
    } catch (e) {
      setState(() { _iniciando = false; _errorInicio = 'No se pudo iniciar el trámite. Revisa los documentos.'; });
    }
  }

  // ── Subida de un documento requerido (cámara / video / archivo) ──────────────

  Future<void> _subirRequisito(int index, RequisitoDocumento req) async {
    final exts = req.mimeTypesPermitidos.map((e) => e.toLowerCase()).toList();
    final permiteImagen = exts.isEmpty || exts.any(_imageExts.contains);
    final permiteVideo = exts.isEmpty || exts.any(_videoExts.contains);

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (permiteImagen)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.active),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, 'foto')),
          if (permiteVideo)
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: AppColors.active),
              title: const Text('Grabar video'),
              onTap: () => Navigator.pop(context, 'video')),
          ListTile(
            leading: const Icon(Icons.folder_open_outlined, color: AppColors.active),
            title: const Text('Elegir archivo'),
            subtitle: Text(_labelTipos(exts), style: const TextStyle(fontSize: 12)),
            onTap: () => Navigator.pop(context, 'archivo')),
        ]),
      ),
    );
    if (choice == null) return;

    String? nombre;
    List<int>? bytes;
    try {
      if (choice == 'foto') {
        final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 2400);
        if (x == null) return;
        nombre = x.name; bytes = await x.readAsBytes();
      } else if (choice == 'video') {
        final x = await ImagePicker().pickVideo(source: ImageSource.camera);
        if (x == null) return;
        nombre = x.name; bytes = await x.readAsBytes();
      } else {
        final allowed = exts.isEmpty ? null : exts.map((e) => e.replaceFirst('.', '')).toList();
        final res = await FilePicker.platform.pickFiles(
          type: allowed == null ? FileType.any : FileType.custom,
          allowedExtensions: allowed,
          withData: true,
        );
        if (res == null || res.files.isEmpty || res.files.first.bytes == null) return;
        nombre = res.files.first.name; bytes = res.files.first.bytes!;
      }
    } catch (_) {
      setState(() => _slots[index] = _SlotDoc(error: 'No se pudo seleccionar el archivo.'));
      return;
    }

    if (!_extPermitida(exts, nombre)) {
      setState(() => _slots[index] = _SlotDoc(error: 'Formato no permitido. Solo: ${_labelTipos(exts)}'));
      return;
    }

    await _subir(index, nombre, bytes);
  }

  Future<void> _subir(int index, String nombre, List<int> bytes) async {
    final empresaId = context.read<AuthService>().user?.empresaId ?? '';
    setState(() => _slots[index] = _SlotDoc(subiendo: true));
    try {
      final pre = await _docService.iniciarUpload(
        nombre: nombre,
        mimeType: _mimeFromName(nombre),
        size: bytes.length,
        empresaId: empresaId,
        tipo: 'ENTRADA',
      );
      await _docService.subirBytes(pre.uploadUrl, bytes, _mimeFromName(nombre));
      setState(() => _slots[index] = _SlotDoc(documentoId: pre.documentoId, nombreArchivo: nombre));
    } catch (_) {
      setState(() => _slots[index] = _SlotDoc(error: 'Error al subir. Intenta de nuevo.'));
    }
  }

  bool _extPermitida(List<String> exts, String nombre) {
    if (exts.isEmpty) return true;
    final i = nombre.lastIndexOf('.');
    final ext = i >= 0 ? nombre.substring(i).toLowerCase() : '';
    return exts.contains(ext);
  }

  String _labelTipos(List<String> exts) =>
      exts.isEmpty ? 'Cualquier formato' : exts.map((e) => e.replaceFirst('.', '').toUpperCase()).join(', ');

  String _mimeFromName(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.gif')) return 'image/gif';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.doc')) return 'application/msword';
    if (n.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (n.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (n.endsWith('.xlsx')) return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (n.endsWith('.csv')) return 'text/csv';
    if (n.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (n.endsWith('.pptx')) return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    if (n.endsWith('.mp4')) return 'video/mp4';
    if (n.endsWith('.webm')) return 'video/webm';
    if (n.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_seleccionado == null ? 'Iniciar trámite' : 'Documentos requeridos'),
        leading: _seleccionado != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _seleccionado = null))
            : null,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _seleccionado == null
              ? _chatView()
              : _docsView(),
    );
  }

  Widget _chatView() {
    return Column(children: [
      Expanded(
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          children: [
            for (final m in _mensajes) _burbuja(m),
            if (_pensando) _burbuja(ChatMensaje('agente', 'Escribiendo…')),
            if (_recomendado != null) _cardRecomendado(_recomendado!),
            if (_opciones.isNotEmpty) _chipsOpciones(),
            const SizedBox(height: 8),
            _elegirDeLista(),
          ],
        ),
      ),
      _inputBar(),
    ]);
  }

  Widget _burbuja(ChatMensaje m) {
    final esUsuario = m.rol == 'usuario';
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: esUsuario ? AppColors.activeLight : AppColors.surface,
          border: Border.all(color: esUsuario ? AppColors.active.withValues(alpha: 0.2) : AppColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(m.mensaje, style: TextStyle(fontSize: 14, color: esUsuario ? AppColors.active : AppColors.textPrimary)),
      ),
    );
  }

  Widget _cardRecomendado(ProcesoPublico p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.completedLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.completed.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.recommend_outlined, color: AppColors.completed, size: 18),
          const SizedBox(width: 6),
          const Text('Trámite recomendado', style: TextStyle(fontSize: 12, color: AppColors.completed, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        Text(p.nombre, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        if (p.descripcion.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 2),
              child: Text(p.descripcion, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _seleccionar(p), child: const Text('Continuar con este trámite'))),
      ]),
    );
  }

  Widget _chipsOpciones() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in _opciones)
          ActionChip(label: Text(o.nombre), onPressed: () => _seleccionarPorId(o.id)),
      ]),
    );
  }

  Widget _elegirDeLista() {
    if (_procesos.isEmpty) return const SizedBox.shrink();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('O elige directamente de la lista', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        children: [
          for (final p in _procesos)
            ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long_outlined, size: 20),
              title: Text(p.nombre, style: const TextStyle(fontSize: 14)),
              subtitle: p.descripcion.isNotEmpty ? Text(p.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _seleccionar(p),
            ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _entradaCtrl,
              minLines: 1, maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
              decoration: const InputDecoration(hintText: 'Escribe qué necesitas...'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _pensando ? null : _enviar,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ]),
      ),
    );
  }

  Widget _docsView() {
    final p = _seleccionado!;
    final reqs = p.documentosRequeridos;
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(p.nombre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            if (p.descripcion.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4),
                  child: Text(p.descripcion, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            const SizedBox(height: 16),
            if (reqs.isEmpty)
              const Text('Este trámite no requiere documentos. Puedes iniciarlo directamente.',
                  style: TextStyle(color: AppColors.textSecondary))
            else
              const Text('Documentos requeridos', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            for (var i = 0; i < reqs.length; i++) _cardRequisito(i, reqs[i]),
            if (_errorInicio != null) ...[
              const SizedBox(height: 8),
              Text(_errorInicio!, style: const TextStyle(color: AppColors.cancelled, fontSize: 13)),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: ElevatedButton.icon(
            onPressed: (_puedeIniciar && !_iniciando) ? _iniciar : null,
            icon: _iniciando
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow),
            label: Text(_iniciando ? 'Iniciando...' : 'Iniciar trámite'),
          ),
        ),
      ),
    ]);
  }

  Widget _cardRequisito(int index, RequisitoDocumento req) {
    final slot = _slots[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(req.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          if (req.obligatorio)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.cancelledLight, borderRadius: BorderRadius.circular(20)),
              child: const Text('Obligatorio', style: TextStyle(fontSize: 11, color: AppColors.cancelled)),
            )
          else
            const Text('Opcional', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
        if (req.descripcion.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 2),
              child: Text(req.descripcion, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        const SizedBox(height: 10),
        if (slot?.subiendo == true)
          const Row(children: [
            SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8), Text('Subiendo...', style: TextStyle(color: AppColors.textSecondary)),
          ])
        else if (slot?.documentoId != null)
          Row(children: [
            const Icon(Icons.check_circle, color: AppColors.completed, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(slot!.nombreArchivo ?? 'Documento subido',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.completed, fontSize: 13))),
            TextButton(onPressed: () => _subirRequisito(index, req), child: const Text('Cambiar')),
          ])
        else
          OutlinedButton.icon(
            onPressed: () => _subirRequisito(index, req),
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Adjuntar'),
          ),
        if (slot?.error != null)
          Padding(padding: const EdgeInsets.only(top: 4),
              child: Text(slot!.error!, style: const TextStyle(color: AppColors.cancelled, fontSize: 12))),
      ]),
    );
  }
}
