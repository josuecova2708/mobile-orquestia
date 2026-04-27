# Orquestia Mobile — App Flutter (Plan Final)

Aplicación Flutter complementaria al BPM Studio web.
Backend: `https://orquestia-backend-139914767846.us-central1.run.app`
Firebase project: `orquestia` (ya existe, mismo proyecto del frontend Angular)

---

## Resumen de Roles y Pantallas

```
App Flutter
├── 🔓 Sin login
│   └── Home/Tracking → buscar instancia por ID → ver timeline
│
├── 👤 Admin (login con JWT)
│   ├── Panel Ejecuciones → Activas / Historial (tabs)
│   ├── Detalle de Instancia → timeline completo
│   └── Invitar Co-Admin → formulario de email
│
└── 👷 Funcionario (login con JWT)
    ├── Mis Tareas → lista de tareas pendientes (redirige a web para resolver)
    ├── Notificaciones → lista con push notifications reales (FCM)
    └── Mi Historial → instancias en que participó
```

---

## Endpoints Backend Utilizados

| Función               | Endpoint                                | Estado       |
| --------------------- | --------------------------------------- | ------------ |
| Login                 | `POST /api/auth/login`                  | ✅ Existente |
| Invitar co-admin      | `POST /api/auth/invitar-admin`          | ✅ Existente |
| Instancias empresa    | `GET /api/instancias?empresaId=X`       | ✅ Existente |
| Detalle instancia     | `GET /api/instancias/{id}`              | ✅ Existente |
| Tareas de instancia   | `GET /api/instancias/{id}/tareas`       | ✅ Existente |
| Cancelar instancia    | `DELETE /api/instancias/{id}`           | ✅ Existente |
| Mis tareas pendientes | `GET /api/mis-tareas`                   | ✅ Existente |
| Mis instancias        | `GET /api/mis-instancias`               | ✅ Existente |
| Notificaciones        | `GET /api/notificaciones`               | ✅ Existente |
| No leídas (count)     | `GET /api/notificaciones/no-leidas`     | ✅ Existente |
| Marcar leída          | `PUT /api/notificaciones/{id}/leer`     | ✅ Existente |
| Marcar todas leídas   | `PUT /api/notificaciones/leer-todas`    | ✅ Existente |
| Registro device token | `POST /api/usuarios/device-token`       | 🆕 Nuevo    |
| Tracking público      | `GET /api/public/instancias/{id}`       | 🆕 Nuevo    |

---

## Cambios en el Backend (no rompen nada existente)

### 1. `pom.xml` — agregar Firebase Admin SDK
```xml
<dependency>
  <groupId>com.google.firebase</groupId>
  <artifactId>firebase-admin</artifactId>
  <version>9.3.0</version>
</dependency>
```

### 2. `Usuario.java` — agregar campo
```java
@Builder.Default
private List<String> deviceTokens = new ArrayList<>();
```

### 3. Nuevo `FcmService.java`
- Inicializa Firebase Admin con Application Default Credentials (Cloud Run ya tiene)
- Método `sendPush(deviceTokens, title, body, data)`

### 4. `NotificacionService.java` — modificar `crear()`
- Inyectar `FcmService` + `UsuarioRepository`
- Al guardar la notificación, buscar el usuario y enviarle push FCM

### 5. Nuevo endpoint `POST /api/usuarios/device-token`
- Body: `{ "token": "string" }`
- Agrega el token FCM al array `deviceTokens` del usuario autenticado
- Al eliminar token: `DELETE /api/usuarios/device-token`

### 6. Nuevo `PublicTrackingController.java`
- `GET /api/public/instancias/{id}` — sin autenticación
- Devuelve solo: id, nombreProceso, estado, fechaInicio, fechaFin, timeline (sin datos sensibles)

### 7. `SecurityConfig.java` — agregar rutas públicas
```java
.requestMatchers("/api/public/**").permitAll()
```

---

## Arquitectura Flutter

```
mobile-orquestia/
├── android/
│   └── app/google-services.json        ← descargar de Firebase Console
├── lib/
│   ├── main.dart                        ← init Firebase, runApp
│   ├── firebase_options.dart            ← generado por flutterfire configure
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart          ← Dio + interceptor JWT
│   │   │   └── api_constants.dart       ← baseUrl, endpoints
│   │   ├── models/
│   │   │   ├── auth_response.dart
│   │   │   ├── instancia.dart
│   │   │   ├── tarea_instancia.dart
│   │   │   └── notificacion.dart
│   │   ├── services/
│   │   │   ├── auth_service.dart
│   │   │   ├── instancia_service.dart
│   │   │   ├── tarea_service.dart
│   │   │   ├── notificacion_service.dart
│   │   │   └── push_notification_service.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   │
│   ├── features/
│   │   ├── tracking/
│   │   │   ├── tracking_screen.dart     ← Home público (buscar por ID)
│   │   │   └── timeline_public_screen.dart
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── admin/
│   │   │   ├── ejecuciones_screen.dart
│   │   │   ├── detalle_instancia_screen.dart
│   │   │   └── invitar_admin_screen.dart
│   │   └── funcionario/
│   │       ├── mis_tareas_screen.dart   ← lista + "resolver en la web"
│   │       ├── notificaciones_screen.dart
│   │       └── historial_screen.dart
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── timeline_stepper.dart
│       │   ├── estado_chip.dart
│       │   └── loading_overlay.dart
│       └── navigation/
│           └── app_router.dart
│
├── pubspec.yaml
└── google-services.json                 ← NO (va en android/app/)
```

---

## Dependencias Flutter (`pubspec.yaml`)

```yaml
dependencies:
  dio: ^5.7.0                    # HTTP client con interceptores
  provider: ^6.1.2               # State management
  shared_preferences: ^2.3.3     # Persistencia local (token JWT)
  go_router: ^14.6.0             # Navegación declarativa
  google_fonts: ^6.2.1           # Tipografía Inter
  intl: ^0.19.0                  # Formateo de fechas
  firebase_core: ^3.6.0          # Firebase base
  firebase_messaging: ^15.1.3    # FCM push notifications
  flutter_local_notifications: ^18.0.0  # Mostrar notif en foreground
```

---

## Push Notifications — Flujo Completo

```
Funcionario abre app
  → Flutter pide permiso de notificaciones
  → Firebase Messaging genera device token
  → App llama POST /api/usuarios/device-token (con JWT)
  → Backend guarda token en usuario.deviceTokens[]

Cuando el BPM motor crea una tarea para ese funcionario:
  → MotorBPMService llama NotificacionService.crear()
  → NotificacionService guarda en DB + llama FcmService.sendPush()
  → FcmService envía push via Firebase Admin SDK
  → Android recibe la notificación (incluso con la app cerrada)
  → Al tocar → abre la app en la pantalla de Notificaciones
```

---

## Pantallas Detalladas

### 🔓 Home / Tracking Público
- Logo Orquestia + título
- Campo de texto: "ID de tu proceso"
- Botón "Rastrear" → llama `/api/public/instancias/{id}`
- Link "Iniciar sesión" abajo

### 🔓 Timeline Público
- Chip de estado (ACTIVA/COMPLETADA/CANCELADA)
- Nombre del proceso + fechas
- Stepper vertical con pasos:
  - COMPLETADA: check verde
  - EN_PROGRESO: círculo azul animado
  - PENDIENTE: círculo gris

### 🔐 Login
- Email + contraseña
- JWT guardado en SharedPreferences
- Redirige según `rol`: ADMIN → Ejecuciones, FUNCIONARIO → Mis Tareas

### 👤 Admin — Ejecuciones
- Tabs: "Activas" / "Historial"
- Cards: nombre proceso, quien lo inició, fecha, chip de estado
- Pull to refresh
- Tap → Detalle

### 👤 Admin — Detalle Instancia
- Header: nombre, estado chip, fechas
- Stepper con todas las tareas (nodoLabel, estado, fecha)
- Si ACTIVA: botón "Cancelar proceso"

### 👤 Admin — Invitar Co-Admin
- Campo email, nombre, apellido, contraseña temporal
- Botón enviar + feedback

### 👷 Funcionario — Mis Tareas
- Lista de tareas PENDIENTE/EN_PROGRESO (`GET /api/mis-tareas`)
- Card: nombre proceso (nodoLabel), departamento, fecha
- Botón "Resolver en la web" → abre URL del frontend web
- Estado vacío: "No tienes tareas pendientes"

### 👷 Funcionario — Notificaciones
- Lista con badge de no leídas
- Pull to refresh
- Tap → marcar leída
- Botón "Marcar todas leídas"

### 👷 Funcionario — Mi Historial
- Lista de instancias en que participó
- Estado chip + fechas
- Pull to refresh

---

## Diseño Visual

Consistente con la web Orquestia:
- **Color primario:** Negro `#0A0A0A`
- **Fondo:** Blanco `#FAFAFA`
- **Bordes:** `#EAEAEA`
- **Semánticos:**
  - ACTIVA/EN_PROGRESO: Azul `#2563EB`
  - COMPLETADA: Verde `#16A34A`
  - CANCELADA/RECHAZADA: Rojo `#DC2626`
  - PENDIENTE/BORRADOR: Gris `#6B7280`
- **Tipografía:** Inter (Google Fonts)
- **Estilo:** Cards con sombra sutil, chips redondeados, minimalista

---

## Plan de Implementación

### Fase 1 — Backend (4 archivos nuevos, 3 modificados)
1. `pom.xml` → agregar firebase-admin 9.3.0
2. `Usuario.java` → agregar `deviceTokens`
3. `FcmService.java` → nuevo, Firebase Admin + envío push
4. `NotificacionService.java` → integrar FcmService
5. Nuevo endpoint device token en `UsuarioController.java`
6. `PublicTrackingController.java` → nuevo, tracking público
7. `SecurityConfig.java` → liberar `/api/public/**`

### Fase 2 — Flutter Core
8. `flutter create` en mobile-orquestia
9. `pubspec.yaml` → dependencias
10. `app_theme.dart` → colores y tipografía
11. `api_client.dart` → Dio + JWT interceptor
12. Models: `auth_response`, `instancia`, `tarea_instancia`, `notificacion`
13. Services: `auth`, `instancia`, `tarea`, `notificacion`, `push_notification`

### Fase 3 — Pantallas
14. Tracking público (Home + Timeline)
15. Login
16. Admin: Ejecuciones + Detalle + Invitar
17. Funcionario: Mis Tareas + Notificaciones + Historial

### Fase 4 — Integración y Pulido
18. Router con roles (go_router)
19. `main.dart` con Firebase init + PushNotificationService
20. Estados vacíos, loading, snackbars

---

## Setup Requerido por el Desarrollador

Antes de compilar la app Flutter:

1. **Descargar `google-services.json`** desde Firebase Console:
   - Firebase Console → Proyecto "orquestia" → Configuración del proyecto
   - Agregar app Android con package name: `com.orquestia.mobile`
   - Descargar y colocar en `android/app/google-services.json`

2. **Service account para el backend** (para FCM en Cloud Run):
   - Cloud Run ya usa Application Default Credentials automáticamente
   - Solo necesita el `project_id` de Firebase en `application.properties`

3. **Ejecutar flutterfire configure** (opcional, ya tenemos firebase_options.dart manual):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=orquestia
   ```
