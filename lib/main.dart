import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
// import 'api.dart'; // Solo descomentar si necesitas sobrescribir la URL base
import 'theme/app_theme.dart';
import 'pages/intro/intro_page.dart';
import 'layouts/main_layout.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'contexts/products_provider.dart';
import 'contexts/points_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Verificar conectividad de red al iniciar (para solicitar permisos si es necesario)
  await _checkNetworkConnectivity();
  
  // Configuración de la API
  // Por defecto:
  // - Modo DEBUG: https://api.maxximundo.com/api/app-shell/dev (con /dev)
  // - Modo RELEASE: https://api.maxximundo.com/api/app-shell (sin /dev)
  // 
  // Si necesitas sobrescribir, descomenta y modifica:
  // import 'api.dart'; (arriba)
  // ApiConfig.setBaseUrl('https://api.maxximundo.com/api/app-shell/dev'); // Con /dev
  // ApiConfig.setBaseUrl('https://api.maxximundo.com/api/app-shell'); // Sin /dev
  
  // Bloquear la rotación de pantalla a modo vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

/// Verifica la conectividad de red al iniciar la app
/// Esto solicita los permisos de red automáticamente en iOS/Android
Future<void> _checkNetworkConnectivity() async {
  try {
    if (kDebugMode) {
      print('🔍 Verificando conectividad con nuevo proveedor de internet...');
      print('📍 Intentando resolver DNS para: api.maxximundo.com');
    }
    
    // Intentar resolver el DNS del dominio de la API
    // Esto activa los permisos de red automáticamente
    final result = await InternetAddress.lookup('api.maxximundo.com')
        .timeout(const Duration(seconds: 5));
    
    if (kDebugMode) {
      if (result.isNotEmpty) {
        print('✅ DNS resuelto correctamente');
        for (var addr in result) {
          print('   IP: ${addr.address} (IPv${addr.type.name})');
        }
        print('💡 Si sigue fallando, puede ser un problema del nuevo proveedor:');
        print('   - Proxy transparente bloqueando peticiones Flutter');
        print('   - Firewall del ISP bloqueando ciertos User-Agents');
        print('   - DNS diferente que no resuelve correctamente');
      } else {
        print('⚠️ DNS no resolvió ninguna IP');
        print('💡 El nuevo proveedor puede estar bloqueando la resolución DNS');
      }
    }
  } catch (e) {
    // Si falla, no es crítico - la app puede funcionar sin conexión inicial
    if (kDebugMode) {
      print('❌ Verificación de DNS falló: $e');
      print('💡 Problema detectado con el nuevo proveedor de internet:');
      print('   - DNS no resuelve: ${e.toString()}');
      print('   - Safari/Postman funcionan pero Flutter no');
      print('   - Posible causa: Proxy/Firewall del nuevo ISP bloqueando Flutter');
      print('   - Solución: Contactar al nuevo proveedor o usar VPN/DNS alternativo');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => PointsProvider()),
      ],
      child: MaterialApp(
        title: 'Shell Maxx',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('es', 'ES'),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final authService = AuthService.instance;
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn) {
        final user = await authService.getCurrentUser();
        if (user != null) {
          setState(() {
            _isLoggedIn = true;
            _user = user;
          });
        }
      }
    } catch (e) {
      // En caso de error, ir a login
      setState(() {
        _isLoggedIn = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn && _user != null) {
      // Si el usuario ya está logueado, ir directo al MainLayout
      // El onboarding solo se maneja durante el flujo de login
      // Si el usuario tiene sesión guardada, significa que ya hizo login antes
      // y el backend ya actualizó su LAST_LOGIN
      return MainLayout(user: _user!);
    } else {
      return const IntroPage();
    }
  }
}
