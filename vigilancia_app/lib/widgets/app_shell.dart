import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'theme_toggle_button.dart';

/// Ancho a partir del cual la app usa barra lateral fija (web / tablet horizontal).
const double kSidebarBreakpoint = 1000;

bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;

// ═══════════════════════════════════════════════════════════════════════════
// Módulos y permisos por rol
// ═══════════════════════════════════════════════════════════════════════════

class AppModule {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const AppModule(this.icon, this.label, this.route, this.color);
}

class AppModules {
  static const List<AppModule> all = [
    AppModule(Icons.space_dashboard_rounded, 'Dashboard', AppRoutes.dashboard, Color(0xFF1A5DC8)),
    AppModule(Icons.map_rounded, 'Mapa', AppRoutes.map, Color(0xFF00897B)),
    AppModule(Icons.videocam_rounded, 'Cámaras', AppRoutes.cameraView, Color(0xFF6D4C41)),
    AppModule(Icons.devices_other_rounded, 'Dispositivos', AppRoutes.devices, Color(0xFF5E35B1)),
    AppModule(Icons.warning_amber_rounded, 'Alertas', AppRoutes.alerts, Color(0xFFE53935)),
    AppModule(Icons.forum_rounded, 'Comunicación', AppRoutes.communication, Color(0xFF0288D1)),
    AppModule(Icons.psychology_rounded, 'IA Hub', AppRoutes.iaModule, Color(0xFF7B1FA2)),
    AppModule(Icons.assessment_rounded, 'Reportes', AppRoutes.reportes, Color(0xFF2E7D32)),
    AppModule(Icons.admin_panel_settings_rounded, 'Admin', AppRoutes.admin, Color(0xFFAD1457)),
  ];

  /// Módulos de la barra inferior en celular.
  static const List<String> bottomNavRoutes = [
    AppRoutes.dashboard,
    AppRoutes.map,
    AppRoutes.cameraView,
    AppRoutes.alerts,
  ];

  static List<AppModule> visibleFor(String role) =>
      all.where((m) => RoleAccess.canAccess(m.route, role)).toList();

  static AppModule? byRoute(String? route) {
    for (final m in all) {
      if (m.route == route) return m;
    }
    return null;
  }
}

class RoleAccess {
  /// Rutas que el visitante (viewer) no puede abrir.
  static const Set<String> _viewerBlocked = {
    AppRoutes.reportes,
    AppRoutes.iaModule,
    AppRoutes.admin,
  };

  static bool canAccess(String? route, String role) {
    if (route == null) return true;
    if (route == AppRoutes.admin) return role == 'admin';
    if (role == 'viewer' && _viewerBlocked.contains(route)) return false;
    return true;
  }

  static String label(String role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'operator':
        return 'Operador';
      default:
        return 'Visitante';
    }
  }

  static Color color(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFAD1457);
      case 'operator':
        return const Color(0xFFF2A100);
      default:
        return const Color(0xFF1A5DC8);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sesión: datos del usuario para menús
// ═══════════════════════════════════════════════════════════════════════════

class UserSnapshot {
  final String name;
  final String email;
  final String role;
  const UserSnapshot(this.name, this.email, this.role);

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  static Future<UserSnapshot> load() async {
    final values = await Future.wait([
      SessionService.getUserName(),
      SessionService.getUserEmail(),
      SessionService.getUserRole(),
    ]);
    return UserSnapshot(values[0], values[1], values[2]);
  }
}

/// Navega a un módulo sin apilar pantallas: el dashboard queda como base.
void navigateToModule(BuildContext context, String route) {
  navigateWith(
    Navigator.of(context),
    ModalRoute.of(context)?.settings.name,
    route,
  );
}

void navigateWith(NavigatorState nav, String? current, String route) {
  if (current == route) return;
  if (route == AppRoutes.dashboard) {
    nav.pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
    return;
  }
  nav.pushNamedAndRemoveUntil(
    route,
    (r) => r.settings.name == AppRoutes.dashboard,
  );
}

/// Cierra la sesión al instante: limpia los datos locales, vuelve al login y
/// revoca el token en el servidor en segundo plano (sin hacer esperar al usuario).
/// Usa el navigatorKey global para no depender de un context ya desmontado.
Future<void> performLogout([BuildContext? context]) async {
  final token = SessionService.cachedToken;
  await SessionService.logout();
  navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  if (token != null && token.isNotEmpty) {
    unawaited(ApiService.revokeToken(token));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Menú desplegable del perfil (nombre, rol, editar perfil, cerrar sesión)
// ═══════════════════════════════════════════════════════════════════════════

class ProfileMenuButton extends StatefulWidget {
  final bool showName;
  const ProfileMenuButton({super.key, this.showName = false});

  @override
  State<ProfileMenuButton> createState() => _ProfileMenuButtonState();
}

class _ProfileMenuButtonState extends State<ProfileMenuButton> {
  late Future<UserSnapshot> _user;

  @override
  void initState() {
    super.initState();
    _user = UserSnapshot.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return FutureBuilder<UserSnapshot>(
      future: _user,
      builder: (context, snap) {
        final user = snap.data ?? const UserSnapshot('Usuario', '', 'viewer');
        final roleColor = RoleAccess.color(user.role);

        return PopupMenuButton<String>(
          tooltip: 'Cuenta',
          offset: const Offset(0, 52),
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    _Avatar(initials: user.initials, color: roleColor, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                          if (user.email.isNotEmpty)
                            Text(user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: c.label)),
                          const SizedBox(height: 6),
                          RoleChip(role: user.role),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            _menuItem('edit_profile', Icons.manage_accounts_rounded, 'Editar perfil', c.text),
            _menuItem('logout', Icons.logout_rounded, 'Cerrar sesión', AppColors.danger),
          ],
          onSelected: (value) async {
            if (value == 'edit_profile') {
              final current = ModalRoute.of(context)?.settings.name;
              if (current == AppRoutes.profile) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.profile,
                (r) => r.settings.name == AppRoutes.dashboard,
                arguments: {'edit': true},
              );
            } else if (value == 'logout') {
              await performLogout();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(initials: user.initials, color: roleColor, radius: 18),
                if (widget.showName) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text)),
                        Text(RoleAccess.label(user.role),
                            style: TextStyle(fontSize: 11, color: c.label)),
                      ],
                    ),
                  ),
                ],
                Icon(Icons.expand_more_rounded, size: 18, color: c.label),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      height: 46,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class RoleChip extends StatelessWidget {
  final String role;
  const RoleChip({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final color = RoleAccess.color(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        RoleAccess.label(role).toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.6),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double radius;
  const _Avatar({required this.initials, required this.color, required this.radius});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Text(
        initials,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: radius * 0.75),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Barra superior común
// ═══════════════════════════════════════════════════════════════════════════

/// Botón de menú (abre el drawer). En pantallas anchas no se muestra porque
/// la barra lateral ya está visible.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (isWideLayout(context)) return const SizedBox.shrink();
    final c = AppColors.of(context);
    return Builder(
      builder: (ctx) => IconButton(
        tooltip: 'Menú',
        onPressed: () => Scaffold.of(ctx).openDrawer(),
        style: IconButton.styleFrom(
          backgroundColor: c.tint(AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.menu_rounded, color: AppColors.primary, size: 22),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final wide = isWideLayout(context);
    return Row(
      children: [
        const AppMenuButton(),
        if (!wide) const SizedBox(width: 10),
        if (icon != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: wide ? 22 : 18,
                  fontWeight: FontWeight.w800,
                  color: c.text,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.label),
                ),
            ],
          ),
        ),
        ...actions,
        const ThemeToggleButton(),
        const SizedBox(width: 6),
        ProfileMenuButton(showName: wide),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Navegación: drawer (celular), barra lateral (web) y barra inferior (celular)
// ═══════════════════════════════════════════════════════════════════════════

class _Brand extends StatelessWidget {
  final bool light;
  const _Brand({this.light = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('S.V.I.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: light ? Colors.white : c.text,
                    letterSpacing: 0.4,
                  )),
              Text('Vigilancia y Monitoreo Integral',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: light ? Colors.white70 : c.label)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavList extends StatelessWidget {
  final String? currentRoute;
  final bool closeDrawerOnTap;
  const _NavList({required this.currentRoute, this.closeDrawerOnTap = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return FutureBuilder<String>(
      future: SessionService.getUserRole(),
      builder: (context, snap) {
        final role = snap.data ?? 'viewer';
        final modules = AppModules.visibleFor(role);
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Text('MÓDULOS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.hint, letterSpacing: 1)),
            ),
            for (final m in modules)
              _NavTile(
                module: m,
                selected: m.route == currentRoute,
                onTap: () {
                  final nav = Navigator.of(context);
                  final current = ModalRoute.of(context)?.settings.name;
                  if (closeDrawerOnTap) nav.pop();
                  navigateWith(nav, current, m.route);
                },
              ),
          ],
        );
      },
    );
  }
}

class _NavTile extends StatelessWidget {
  final AppModule module;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.module, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? c.tint(AppColors.primary) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected ? module.color : c.tint(module.color),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(module.icon, size: 19, color: selected ? Colors.white : module.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    module.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : c.text,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final bool closeDrawer;
  const _LogoutTile({this.closeDrawer = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
        title: const Text('Cerrar sesión',
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
        onTap: () {
          if (closeDrawer) Navigator.pop(context);
          performLogout();
        },
      ),
    );
  }
}

/// Drawer lateral para celular. Reemplaza los drawers que tenía cada pantalla.
class AppDrawer extends StatelessWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 290,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF0B1F44)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const _Brand(light: true),
            ),
            Expanded(child: _NavList(currentRoute: currentRoute, closeDrawerOnTap: true)),
            const Divider(height: 1),
            const _LogoutTile(closeDrawer: true),
          ],
        ),
      ),
    );
  }
}

/// Barra lateral fija para web / pantallas anchas.
class AppSidebar extends StatelessWidget {
  final String? currentRoute;
  const AppSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.sidebar,
      child: Container(
      width: 264,
      decoration: BoxDecoration(
        color: c.sidebar,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: _Brand(),
            ),
            Expanded(child: _NavList(currentRoute: currentRoute)),
            const Divider(height: 1),
            const _LogoutTile(),
          ],
        ),
      ),
    ),
    );
  }
}

/// Barra inferior para celular con los módulos más usados y un botón "Más".
class AppBottomNav extends StatelessWidget {
  final String? currentRoute;
  const AppBottomNav({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final items = AppModules.bottomNavRoutes
        .map((r) => AppModules.byRoute(r)!)
        .toList();
    final index = items.indexWhere((m) => m.route == currentRoute);

    return NavigationBar(
      selectedIndex: index < 0 ? items.length : index,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) {
        if (i == items.length) {
          _showMoreSheet(context);
        } else {
          navigateToModule(context, items[i].route);
        }
      },
      destinations: [
        for (final m in items)
          NavigationDestination(
            icon: Icon(m.icon),
            label: m.label == 'Dashboard' ? 'Inicio' : m.label,
          ),
        const NavigationDestination(icon: Icon(Icons.apps_rounded), label: 'Más'),
      ],
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final c = AppColors.of(sheetCtx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: FutureBuilder<String>(
              future: SessionService.getUserRole(),
              builder: (_, snap) {
                final role = snap.data ?? 'viewer';
                final modules = AppModules.visibleFor(role)
                    .where((m) => !AppModules.bottomNavRoutes.contains(m.route))
                    .toList();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Más módulos',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text)),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.05,
                      children: [
                        for (final m in modules)
                          ModuleTile(
                            module: m,
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              navigateToModule(context, m.route);
                            },
                          ),
                        ModuleTile(
                          module: const AppModule(
                              Icons.manage_accounts_rounded, 'Mi perfil', AppRoutes.profile, Color(0xFF455A64)),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            navigateToModule(context, AppRoutes.profile);
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta de acceso a un módulo (dashboard y menú "Más").
class ModuleTile extends StatelessWidget {
  final AppModule module;
  final VoidCallback onTap;
  const ModuleTile({super.key, required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.tint(module.color), borderRadius: BorderRadius.circular(14)),
                child: Icon(module.icon, color: module.color, size: 23),
              ),
              const SizedBox(height: 8),
              Text(
                module.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marco de cada pantalla protegida.
/// - Web / pantallas anchas: barra lateral fija a la izquierda.
/// - Celular: barra inferior en los módulos principales.
///
/// La pantalla se envuelve con una GlobalKey para que no pierda su estado
/// (texto escrito, pestañas, scroll) cuando cambia el layout, por ejemplo al
/// abrir el teclado o al redimensionar la ventana del navegador.
class AppFrame extends StatefulWidget {
  final Widget child;
  final String? currentRoute;
  const AppFrame({super.key, required this.child, required this.currentRoute});

  @override
  State<AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends State<AppFrame> {
  final GlobalKey _pageKey = GlobalKey();

  static const Set<String> _noBottomNav = {
    AppRoutes.communication, // la caja de texto va abajo
    AppRoutes.cameraView, // controles de video abajo
    AppRoutes.profile,
  };

  @override
  Widget build(BuildContext context) {
    final page = KeyedSubtree(key: _pageKey, child: widget.child);

    if (isWideLayout(context)) {
      return Row(
        children: [
          AppSidebar(currentRoute: widget.currentRoute),
          Expanded(child: page),
        ],
      );
    }

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNav = !_noBottomNav.contains(widget.currentRoute) && !keyboardOpen;

    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: showNav,
            child: page,
          ),
        ),
        if (showNav)
          Material(
            child: AppBottomNav(currentRoute: widget.currentRoute),
          ),
      ],
    );
  }
}

/// Encabezado de sección reutilizable.
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text, letterSpacing: -0.2)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Contenedor de tarjeta con el estilo del proyecto.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      // Material transparente para que ListTile/InkWell pinten encima del fondo.
      child: Material(type: MaterialType.transparency, child: child),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: content),
    );
  }
}
