import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'shared/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (si falla por placeholder, la app sigue funcionando sin push)
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await PushNotificationService.init();
  } catch (_) {
    // Firebase no configurado aún — app funciona sin push notifications
  }

  ApiClient().init();

  runApp(const OrquestiaApp());
}

class OrquestiaApp extends StatefulWidget {
  const OrquestiaApp({super.key});

  @override
  State<OrquestiaApp> createState() => _OrquestiaAppState();
}

class _OrquestiaAppState extends State<OrquestiaApp> {
  late final AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthService();
    _auth.tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _auth,
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthService>();
          final router = AppRouter.build(auth);
          return MaterialApp.router(
            title: 'Orquestia',
            theme: AppTheme.light,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
