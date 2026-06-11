class ApiConstants {
  static const baseUrl = 'https://orquestia-backend-139914767846.us-central1.run.app/api';
  static const webUrl = 'https://orquestia-frontend-139914767846.us-central1.run.app';
  static const iaBaseUrl = 'https://orquestia-ia-139914767846.us-central1.run.app';

  // Recepción (chatbot IA) — el servicio IA es público (sin JWT)
  static const clasificarTramite = '/ia/clasificar-tramite';
  // Procesos públicos habilitados para clientes
  static const procesosPublicos = '/procesos/publicos';
  // Iniciar trámite como cliente
  static const clienteIniciarTramite = '/cliente/iniciar-tramite';

  // Auth
  static const login = '/auth/login';
  static const invitarAdmin = '/auth/invitar-admin';

  // Instancias
  static const instancias = '/instancias';
  static String instanciaById(String id) => '/instancias/$id';
  static String tareasPorInstancia(String id) => '/instancias/$id/tareas';

  // Tareas del usuario
  static const misTareas = '/mis-tareas';
  static const misInstancias = '/mis-instancias';
  static String completarTarea(String id) => '/tareas/$id/completar';
  static String iniciarTarea(String id) => '/tareas/$id/iniciar';

  // Cliente
  static const clienteMisTramites = '/cliente/mis-tramites';
  static const clienteMisAcciones = '/cliente/mis-acciones';
  static const clienteMisDocumentos = '/cliente/mis-documentos';
  static String clienteTramiteDetalle(String id) => '/cliente/tramites/$id/detalle';
  static String clienteCompletarAccion(String id) => '/cliente/acciones/$id/completar';

  // Documentos (subida con presigned URL — sirve para cámara)
  static const documentoIniciarUpload = '/documentos/iniciar-upload';
  static String documentoDescargar(String id) => '/documentos/$id/descargar';

  // Notificaciones
  static const notificaciones = '/notificaciones';
  static const notificacionesNoLeidas = '/notificaciones/no-leidas';
  static const notificacionesLeerTodas = '/notificaciones/leer-todas';
  static String notificacionLeer(String id) => '/notificaciones/$id/leer';

  // Device token FCM
  static const deviceToken = '/usuarios/device-token';

  // Test FCM
  static const testPush = '/test/push';

  // Público (sin JWT)
  static String publicInstancia(String id) => '/public/instancias/$id';
}
