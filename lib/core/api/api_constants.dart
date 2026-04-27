class ApiConstants {
  static const baseUrl = 'https://orquestia-backend-139914767846.us-central1.run.app/api';
  static const webUrl = 'https://orquestia-frontend-139914767846.us-central1.run.app';

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
