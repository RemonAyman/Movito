import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/movie_detail_screen.dart';
import 'ui/screens/reset_password_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MovieApp(isLoggedIn: isLoggedIn));
}

class MovieApp extends StatefulWidget {
  final bool isLoggedIn;
  const MovieApp({super.key, required this.isLoggedIn});

  @override
  State<MovieApp> createState() => _MovieAppState();
}

class _MovieAppState extends State<MovieApp> {
  late bool _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.isLoggedIn;
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movito',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.neonGlow,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.neonGlow,
          brightness: Brightness.dark,
          surface: AppColors.darkBg,
        ),
        scaffoldBackgroundColor: AppColors.darkBg,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      initialRoute: _isLoggedIn ? '/home' : '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (context) =>
                  LoginScreen(onLoginSuccess: _onLoginSuccess),
            );
          case '/signup':
            return MaterialPageRoute(
              builder: (context) => const SignUpScreen(),
            );
          case '/home':
            return MaterialPageRoute(builder: (context) => const HomeScreen());
          case '/resetPassword':
            return MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
            );
          case '/details':
            final movieId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => MovieDetailScreen(movieId: movieId),
            );
          default:
            return MaterialPageRoute(
              builder: (context) =>
                  LoginScreen(onLoginSuccess: _onLoginSuccess),
            );
        }
      },
    );
  }
}
