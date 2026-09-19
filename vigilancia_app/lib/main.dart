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
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  await themeController.load();
  runApp(MyApp(initialRoute: token != null ? '/dashboard' : '/login'));
}

// ── Servicio de sesión (disponible globalmente) ───────────────────
class SessionService {
  static const _tokenKey     = 'auth_token';
  static const _userNameKey  = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey  = 'user_role';
  static const _userIdKey    = 'user_id';

  /// Guarda el token y datos del usuario tras login exitoso
  static Future<void> saveSession({
    required String token,
    required String name,
    required String email,
    required String role,
    required int    userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userRoleKey, role);
    await prefs.setInt(_userIdKey, userId);
  }

  /// Recupera el token almacenado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Recupera nombre del usuario
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? 'Usuario';
  }

  /// Recupera email del usuario
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey) ?? 'correo@ejemplo.com';
  }

  /// Recupera rol del usuario
  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey) ?? 'viewer';
  }

  /// Recupera ID del usuario
  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey) ?? 0;
  }

  /// Verifica si el usuario es admin
  static Future<bool> isAdmin() async {
    return (await getUserRole()) == 'admin';
  }

  /// Verifica si el usuario es operador o admin
  static Future<bool> canOperate() async {
    final role = await getUserRole();
    return role == 'admin' || role == 'operator';
  }

  /// Cierra sesión y limpia el almacenamiento (conserva el tema)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
  }

  /// Verifica si hay sesión activa
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

// ── App principal ─────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Sentinel Surveillance',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeController.mode,
          initialRoute: initialRoute,
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
  bool _checking = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await SessionService.isLoggedIn();
    if (!mounted) return;
    if (!loggedIn) {
      // Sin sesión → ir al login y limpiar el stack
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.login, (_) => false);
    } else {
      setState(() {
        _authenticated = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A5DC8)),
        ),
      );
    }
    return _authenticated ? widget.child : const SizedBox.shrink();
  }
}