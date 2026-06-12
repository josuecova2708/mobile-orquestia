import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/campo_formulario.dart';
import '../../core/services/documento_service.dart';
import '../../core/theme/app_theme.dart';

const _imageExts = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
const _videoExts = ['.mp4', '.webm', '.mov'];

/// Pantalla reutilizable para completar una tarea/acción con formulario dinámico.
/// La usan tanto el CLIENTE (acciones de autoservicio) como el FUNCIONARIO (sus tareas).
/// Los campos ARCHIVO permiten tomar foto con la cámara o elegir de la galería.
class CompletarTareaScreen extends StatefulWidget {
  final String titulo;
  final List<CampoFormulario> campos;
  final String empresaId;
  final String instanciaId;
  final String tareaId;

  /// Acción de envío: el caller decide a qué endpoint llamar (cliente o funcionario).
  final Future<void> Function(Map<String, dynamic> datos, String comentario) onSubmit;

  const CompletarTareaScreen({
    super.key,
    required this.titulo,
    required this.campos,
    required this.empresaId,
    required this.instanciaId,
    required this.tareaId,
    required this.onSubmit,
  });

  @override
  State<CompletarTareaScreen> createState() => _CompletarTareaScreenState();
}

class _CompletarTareaScreenState extends State<CompletarTareaScreen> {
  final _docService = DocumentoService();
  final _respuestas = <String, dynamic>{};
  final _uploadEstados = <String, String>{}; // idle | uploading | done | error
  final _comentarioCtrl = TextEditingController();
  bool _guardando = false;
  String? _error;

  late final List<CampoFormulario> _campos;

  @override
  void initState() {
    super.initState();
    _campos = widget.campos.isNotEmpty
        ? widget.campos
        : [CampoFormulario(nombre: 'confirmacion', tipo: 'BOOLEANO', label: 'Confirmo esta acción', requerido: true)];
    // Inicializar GRIDs
    for (final c in _campos) {
      if (c.tipo == 'GRID') {
        final filas = c.filas ?? 1;
        final cols = c.columnas.isEmpty ? 1 : c.columnas.length;
        _respuestas[c.nombre] = List.generate(filas, (_) => List.filled(cols, ''));
      }
    }
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  bool _faltaRequerido() {
    for (final c in _campos) {
      if (!c.requerido) continue;
      final v = _respuestas[c.nombre];
      if (v is List) {
        if (v.isEmpty) return true;
        continue;
      }
      if (v == null || v == '' || (v is String && v.trim().isEmpty)) return true;
    }
    return false;
  }

  bool _casillaMarcada(String campo, String op) {
    final v = _respuestas[campo];
    return v is List && v.contains(op);
  }

  void _toggleCasilla(String campo, String op) {
    final actual = _respuestas[campo] is List ? List<String>.from(_respuestas[campo] as List) : <String>[];
    if (actual.contains(op)) {
      actual.remove(op);
    } else {
      actual.add(op);
    }
    _respuestas[campo] = actual;
  }

  Future<void> _enviar() async {
    if (_guardando) return;
    final subiendo = _uploadEstados.values.any((e) => e == 'uploading');
    if (subiendo) {
      setState(() => _error = 'Espera a que terminen de subirse los archivos.');
      return;
    }
    if (_faltaRequerido()) {
      setState(() => _error = 'Completa todos los campos requeridos.');
      return;
    }
    setState(() { _guardando = true; _error = null; });
    try {
      await widget.onSubmit(_respuestas, _comentarioCtrl.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _guardando = false; _error = 'No se pudo completar. Intenta de nuevo.'; });
    }
  }

  // ── Subida de archivos (respeta los formatos que configuró el admin) ─────────

  /// Extensiones permitidas del campo (minúsculas, con punto). Vacío = cualquiera.
  List<String> _exts(CampoFormulario c) => c.mimeTypesPermitidos.map((e) => e.toLowerCase()).toList();

  bool _permiteGrupo(CampoFormulario c, List<String> grupo) {
    final exts = _exts(c);
    return exts.isEmpty || exts.any(grupo.contains);
  }

  bool _extPermitida(CampoFormulario c, String nombre) {
    final exts = _exts(c);
    if (exts.isEmpty) return true;
    final i = nombre.lastIndexOf('.');
    final ext = i >= 0 ? nombre.substring(i).toLowerCase() : '';
    return exts.contains(ext);
  }

  Future<void> _elegirOrigen(CampoFormulario campo) async {
    final permiteImagen = _permiteGrupo(campo, _imageExts);
    final permiteVideo = _permiteGrupo(campo, _videoExts);

    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (permiteImagen)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.active),
                title: const Text('Tomar foto'),
                onTap: () { Navigator.pop(context); _capturarImagen(campo); },
              ),
            if (permiteVideo)
              ListTile(
                leading: const Icon(Icons.videocam_outlined, color: AppColors.active),
                title: const Text('Grabar video'),
                onTap: () { Navigator.pop(context); _capturarVideo(campo); },
              ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined, color: AppColors.active),
              title: const Text('Elegir archivo'),
              subtitle: Text(_labelTipos(campo), style: const TextStyle(fontSize: 12)),
              onTap: () { Navigator.pop(context); _elegirArchivo(campo); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capturarImagen(CampoFormulario campo) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 2400);
      if (x == null) return;
      await _subir(campo, x.name, await x.readAsBytes());
    } catch (_) {
      setState(() => _uploadEstados[campo.nombre] = 'error');
    }
  }

  Future<void> _capturarVideo(CampoFormulario campo) async {
    try {
      final x = await ImagePicker().pickVideo(source: ImageSource.camera);
      if (x == null) return;
      await _subir(campo, x.name, await x.readAsBytes());
    } catch (_) {
      setState(() => _uploadEstados[campo.nombre] = 'error');
    }
  }

  Future<void> _elegirArchivo(CampoFormulario campo) async {
    try {
      final exts = _exts(campo);
      final allowed = exts.isEmpty ? null : exts.map((e) => e.replaceFirst('.', '')).toList();
      final result = await FilePicker.platform.pickFiles(
        type: allowed == null ? FileType.any : FileType.custom,
        allowedExtensions: allowed,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final bytes = f.bytes;
      if (bytes == null) return;
      await _subir(campo, f.name, bytes);
    } catch (_) {
      setState(() => _uploadEstados[campo.nombre] = 'error');
    }
  }

  /// Valida la extensión contra lo permitido y sube por la URL presignada.
  Future<void> _subir(CampoFormulario campo, String nombre, List<int> bytes) async {
    if (!_extPermitida(campo, nombre)) {
      setState(() => _uploadEstados[campo.nombre] = 'tipo');
      return;
    }
    setState(() => _uploadEstados[campo.nombre] = 'uploading');
    try {
      final url = await _docService.subirArchivo(
        nombre: nombre,
        mimeType: _mimeFromName(nombre),
        bytes: bytes,
        empresaId: widget.empresaId,
        instanciaId: widget.instanciaId,
        tareaId: widget.tareaId,
      );
      setState(() {
        _respuestas[campo.nombre] = url;
        _uploadEstados[campo.nombre] = 'done';
      });
    } catch (_) {
      setState(() => _uploadEstados[campo.nombre] = 'error');
    }
  }

  /// Texto legible de los formatos permitidos (vacío = cualquiera).
  String _labelTipos(CampoFormulario c) {
    final exts = _exts(c);
    if (exts.isEmpty) return 'Cualquier formato';
    return exts.map((e) => e.replaceFirst('.', '').toUpperCase()).join(', ');
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final campo in _campos) ...[
            _label(campo),
            const SizedBox(height: 6),
            _buildCampo(campo),
            const SizedBox(height: 18),
          ],
          _label(CampoFormulario(nombre: '_c', tipo: 'TEXTO', label: 'Comentario (opcional)', requerido: false)),
          const SizedBox(height: 6),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Algo que quieras agregar...'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cancelledLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppColors.cancelled, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.cancelled, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _guardando ? null : _enviar,
            icon: _guardando
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, size: 18),
            label: Text(_guardando ? 'Enviando...' : 'Enviar'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _label(CampoFormulario c) => Row(children: [
        Flexible(child: Text(c.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        if (c.requerido) const Text(' *', style: TextStyle(color: AppColors.cancelled)),
      ]);

  Widget _buildCampo(CampoFormulario c) {
    switch (c.tipo) {
      case 'BOOLEANO':
        return RadioGroup<bool>(
          groupValue: _respuestas[c.nombre] as bool?,
          onChanged: (v) => setState(() => _respuestas[c.nombre] = v),
          child: const Row(children: [
            _RadioBool(value: true, label: 'Sí'),
            SizedBox(width: 16),
            _RadioBool(value: false, label: 'No'),
          ]),
        );
      case 'OPCIONES':
        return DropdownButtonFormField<String>(
          initialValue: _respuestas[c.nombre] as String?,
          items: c.opciones.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) => setState(() => _respuestas[c.nombre] = v),
          decoration: const InputDecoration(hintText: 'Selecciona...'),
        );
      case 'CASILLAS':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final op in c.opciones)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                value: _casillaMarcada(c.nombre, op),
                title: Text(op),
                onChanged: (_) => setState(() => _toggleCasilla(c.nombre, op)),
              ),
          ],
        );
      case 'NUMERO':
        return TextField(
          keyboardType: TextInputType.number,
          onChanged: (v) => _respuestas[c.nombre] = v,
          decoration: const InputDecoration(hintText: '0'),
        );
      case 'FECHA':
        return _fechaField(c);
      case 'ARCHIVO':
        return _archivoField(c);
      case 'GRID':
        return _gridField(c);
      default:
        return TextField(
          maxLines: 2,
          minLines: 1,
          onChanged: (v) => _respuestas[c.nombre] = v,
          decoration: const InputDecoration(hintText: 'Escribe aquí...'),
        );
    }
  }

  Widget _fechaField(CampoFormulario c) {
    final actual = _respuestas[c.nombre] as String?;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, minimumSize: const Size(double.infinity, 48)),
      icon: const Icon(Icons.calendar_today_outlined, size: 18),
      label: Text(actual ?? 'Seleccionar fecha', style: const TextStyle(fontWeight: FontWeight.w400)),
      onPressed: () async {
        final hoy = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: hoy,
          firstDate: DateTime(hoy.year - 5),
          lastDate: DateTime(hoy.year + 5),
        );
        if (d != null) {
          setState(() => _respuestas[c.nombre] =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
        }
      },
    );
  }

  Widget _archivoField(CampoFormulario c) {
    final estado = _uploadEstados[c.nombre] ?? 'idle';
    if (estado == 'uploading') {
      return const Row(children: [
        SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 10),
        Text('Subiendo...', style: TextStyle(color: AppColors.textSecondary)),
      ]);
    }
    if (estado == 'done') {
      return Row(children: [
        const Icon(Icons.check_circle, color: AppColors.completed, size: 20),
        const SizedBox(width: 8),
        const Expanded(child: Text('Archivo subido', style: TextStyle(color: AppColors.completed))),
        TextButton(onPressed: () => _elegirOrigen(c), child: const Text('Cambiar')),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      OutlinedButton.icon(
        onPressed: () => _elegirOrigen(c),
        icon: const Icon(Icons.attach_file, size: 18),
        label: const Text('Adjuntar archivo'),
      ),
      const SizedBox(height: 4),
      Text('Formatos permitidos: ${_labelTipos(c)}',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      if (estado == 'error')
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Error al subir. Intenta de nuevo.', style: TextStyle(color: AppColors.cancelled, fontSize: 12)),
        ),
      if (estado == 'tipo')
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Formato no permitido. Solo: ${_labelTipos(c)}',
              style: const TextStyle(color: AppColors.cancelled, fontSize: 12)),
        ),
    ]);
  }

  Widget _gridField(CampoFormulario c) {
    final filas = c.filas ?? 1;
    final cols = c.columnas;
    final matriz = _respuestas[c.nombre] as List<List<String>>;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [for (final col in cols) DataColumn(label: Text(col))],
        rows: [
          for (int f = 0; f < filas; f++)
            DataRow(cells: [
              for (int ci = 0; ci < cols.length; ci++)
                DataCell(SizedBox(
                  width: 110,
                  child: TextField(
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    onChanged: (v) => matriz[f][ci] = v,
                  ),
                )),
            ]),
        ],
      ),
    );
  }
}

/// Radio booleano usado dentro de un `RadioGroup` (API nueva de Flutter).
class _RadioBool extends StatelessWidget {
  final bool value;
  final String label;
  const _RadioBool({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [Radio<bool>(value: value), Text(label)],
      );
}
