# S.V.I. — Sistema de Vigilancia y Monitoreo Integral

S.V.I. es una plataforma de videovigilancia inteligente compuesta por dos partes que trabajan juntas:

- **`vigilancia-api/`** — Backend en **Laravel 12** (PHP) que expone una API REST protegida con **Laravel Sanctum**. Administra usuarios, dispositivos (cámaras), alertas, reportes, mensajes y el mapa de nodos.
- **`vigilancia_app/`** — Aplicación cliente en **Flutter**, multiplataforma (Android, iOS, Windows, Linux, macOS y Web), que consume esa API y es la interfaz con la que interactúa el usuario final.

El backend ya está desplegado en producción (`https://humberto.alwaysdata.net/api`) y la app Flutter viene configurada por defecto para apuntar a esa API, así que **no es necesario levantar ningún servidor para probar el sistema**: basta con ejecutar la app.

## Cómo probar el proyecto

1. Cloná el repositorio y entrá a la carpeta de la app:
   ```bash
   git clone https://github.com/WsantoFCMB420/Sistema-de-vigilancia-y-monitoreo-integral-SVI.git
   cd Sistema-de-vigilancia-y-monitoreo-integral-SVI/vigilancia_app
   ```
2. Instalá las dependencias de Flutter:
   ```bash
   flutter pub get
   ```
3. Ejecutá la app en el dispositivo/emulador o navegador que prefieras:
   ```bash
   flutter run
   ```
4. En la pantalla de **inicio de sesión**, ingresá con el usuario de prueba:

   - **Usuario:** `DMSC@gmail.com`
   - **Contraseña:** `123456789`

Con esa cuenta ya se puede navegar por el dashboard, ver dispositivos, alertas, el mapa, los mensajes, el módulo de IA y los reportes, según los permisos habilitados para ese usuario.

> Nota: la app trae la URL de la API ya "quemada" en `lib/services/api_service.dart` (`baseUrl = "https://humberto.alwaysdata.net/api"`), apuntando al backend en línea. Si se corre en un emulador Android y se quisiera usar un backend local en vez del de producción, esa URL debe cambiarse a `10.0.2.2`; en un dispositivo físico, a la IP local del equipo.

## ¿Qué hace el sistema?

### Autenticación y roles
El login se hace contra `/api/login` (Sanctum genera un token que la app guarda localmente). Existen tres roles: **admin**, **operator** y **viewer**, y el backend restringe ciertas rutas (por ejemplo, la gestión de usuarios) solo al rol admin.

### Dashboard
Pantalla principal con el resumen del estado del sistema (dispositivos activos, alertas recientes, etc.).

### Dispositivos (cámaras)
CRUD completo de dispositivos: alta, edición, baja y control **PTZ** (Pan-Tilt-Zoom) para cámaras que lo soportan, además de la visualización en vivo (incluye soporte para usar la cámara del propio equipo como fuente local).

### Alertas
Registro y ciclo de vida de alertas de seguridad (creación, actualización, cambio de estado y eliminación), con tipo, prioridad, ubicación y dispositivo asociado.

### Mapa
Visualización geográfica de los nodos/dispositivos del sistema.

### Mensajería
Canal simple de mensajes entre usuarios del sistema.

### Módulo de IA
Panel tipo "AI Hub" que simula la detección inteligente de eventos (merodeo, aglomeraciones, etc.) con métricas de precisión y carga de red en tiempo real, pensado como demostración del módulo de inteligencia artificial del sistema.

### Reportes y panel de administración
Generación de reportes de actividad, y un panel exclusivo para administradores donde se gestionan los usuarios y sus roles.

## Estructura del repositorio

```
├── vigilancia-api/     # Backend Laravel (API REST + Sanctum + MySQL)
└── vigilancia_app/     # App cliente Flutter (Android/iOS/Windows/Linux/macOS/Web)
```

## Correr el backend en local (opcional)

Si en vez de usar la API en producción se quiere levantar el backend localmente:

```bash
cd vigilancia-api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

El `seed` crea usuarios de ejemplo con distintos roles (administrador, operadores y viewer) directamente en la base de datos local, útiles para probar los distintos niveles de permisos del sistema.
