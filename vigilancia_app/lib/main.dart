import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Screens ───────────────────────────────────────────────────────
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/camera_view_screen.dart';
import 'screens/map_screen.dart';
import 'screens/devices_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/communication_screen.dart';
import 'screens/ia_module_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/profile_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/app_shell.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  SessionService.init(prefs);
  final token = SessionService.cachedToken;
  await themeController.load();

  ApiService.onUnauthorized = () async {
    SessionService.expiredNotice = true;
    await SessionService.logout();
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  };

  runApp(MyApp(initialRoute: token != null ? '/dashboard' : '/login'));
}

// ── Servicio de sesión (disponible globalmente) ───────────────────
/// Los datos de la sesión se guardan en SharedPreferences y además se
/// mantienen en memoria, así cada pantalla los lee al instante sin esperar
/// al almacenamiento.
class SessionService {
  static const _tokenKey     = 'auth_token';
  static const _userNameKey  = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey  = 'user_role';
  static const _userIdKey    = 'user_id';
  static bool expiredNotice = false;

  static String? _token;
  static String _name = 'Usuario';
  static String _email = '';
  static String _role = 'viewer';
  static int _id = 0;

  /// Carga la sesión guardada en memoria (se llama una vez al iniciar).
  static void init(SharedPreferences prefs) {
    _token = prefs.getString(_tokenKey);
    _name = prefs.getString(_userNameKey) ?? 'Usuario';
    _email = prefs.getString(_userEmailKey) ?? '';
    _role = prefs.getString(_userRoleKey) ?? 'viewer';
    _id = prefs.getInt(_userIdKey) ?? 0;
  }

  static String? get cachedToken => _token;
  static String get cachedRole => _role;
  static int get cachedUserId => _id;

  /// Guarda el token y datos del usuario tras login exitoso
  static Future<void> saveSession({
    required String token,
    required String name,
    required String email,
    required String role,
    required int    userId,
  }) async {
    _token = token;
    _name = name;
    _email = email;
    _role = role;
    _id = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userRoleKey, role);
    await prefs.setInt(_userIdKey, userId);
  }

  /// Actualiza el nombre guardado (tras editar el perfil)
  static Future<void> updateName(String name) async {
    _name = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  static Future<String?> getToken() async => _token;
  static Future<String> getUserName() async => _name;
  static Future<String> getUserEmail() async => _email;
  static Future<String> getUserRole() async => _role;
  static Future<int> getUserId() async => _id;

  static Future<bool> isAdmin() async => _role == 'admin';

  static Future<bool> canOperate() async => _role == 'admin' || _role == 'operator';

  /// Cierra sesión y limpia el almacenamiento (conserva el tema)
  static Future<void> logout() async {
    _token = null;
    _name = 'Usuario';
    _email = '';
    _role = 'viewer';
    _id = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
  }

  /// Verifica si hay sesión activa
  static Future<bool> isLoggedIn() async => _token != null && _token!.isNotEmpty;
}

// ── App principal ─────────────────────────────────────────────────
class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ApiService.validateSession(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'SVI',
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          initialRoute: widget.initialRoute,
          routes: AppRoutes.routes,
          onUnknownRoute: (_) => MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      },
    );
  }
}

// ── Rutas de la aplicación ────────────────────────────────────────
class AppRoutes {
  // Nombres de rutas (úsalos con Navigator.pushNamed)
  static const String login         = '/login';
  static const String register      = '/register';
  static const String dashboard     = '/dashboard';
  static const String cameraView    = '/camera-view';
  static const String map           = '/map';
  static const String devices       = '/devices';
  static const String alerts        = '/alerts';
  static const String communication = '/communication';
  static const String iaModule      = '/ia-module';
  static const String reportes      = '/reportes';
  static const String admin         = '/admin';
  static const String profile       = '/profile';

  static Map<String, WidgetBuilder> get routes => {
    login:         (_) => const LoginScreen(),
    register:      (_) => const RegisterScreen(),
    dashboard:     (_) => const AuthGuard(child: DashboardScreen()),
    cameraView:    (_) => const AuthGuard(child: CameraViewScreen()),
    map:           (_) => const AuthGuard(child: MapScreen()),
    devices:       (_) => const AuthGuard(child: DevicesScreen()),
    alerts:        (_) => const AuthGuard(child: AlertsScreen()),
    communication: (_) => const AuthGuard(child: CommunicationScreen()),
    iaModule:      (_) => const AuthGuard(child: IAModuleScreen()),
    reportes:      (_) => const AuthGuard(child: ReportesScreen()),
    admin:         (_) => const AuthGuard(child: AdminPanelScreen()),
    profile:       (_) => const AuthGuard(child: ProfileScreen()),
  };
}

// ── Guard de autenticación ────────────────────────────────────────
/// Envuelve cualquier pantalla protegida.
/// Si no hay token → redirige al Login automáticamente.
class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  /// null = permitido; si no, la ruta a la que se debe redirigir.
  String? _redirectTo;
  String? _routeName;
  bool _resolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved) return;
    _resolved = true;
    _routeName = ModalRoute.of(context)?.settings.name;

    // Todo se decide con la sesión en memoria: sin esperas ni pantallas de carga.
    final token = SessionService.cachedToken;
    if (token == null || token.isEmpty) {
      _redirectTo = AppRoutes.login;
    } else if (!RoleAccess.canAccess(_routeName, SessionService.cachedRole)) {
      // El visitante no entra a Reportes, IA Hub ni Admin aunque escriba la ruta.
      _redirectTo = AppRoutes.dashboard;
    }

    if (_redirectTo != null) {
      final target = _redirectTo!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (target == AppRoutes.dashboard) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Tu rol no tiene acceso a ese módulo.'),
              backgroundColor: Color(0xFFE53935),
            ),
          );
        }
        Navigator.pushNamedAndRemoveUntil(context, target, (_) => false);
      });
      return;
    }

    // El token se valida con el servidor en segundo plano. Si ya no sirve,
    // ApiService cierra la sesión y lleva al login.
    ApiService.validateSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_redirectTo != null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return AppFrame(currentRoute: _routeName, child: widget.child);
  }
}
