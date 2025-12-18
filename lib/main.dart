import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'pages/intro/intro_page.dart';
import 'layouts/main_layout.dart';
import 'services/auth_service.dart';
import 'models/user_model.dart';
import 'contexts/products_provider.dart';
import 'contexts/points_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Bloquear la rotación de pantalla a modo vertical
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
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
