import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/movie_detail_screen.dart';
import 'ui/screens/reset_password_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/edit_profile_screen.dart';
import 'ui/screens/add_friend_screen.dart';
import 'ui/screens/friend_requests_screen.dart';
import 'ui/screens/friends_screen.dart';
import 'ui/screens/chat_list_screen.dart';
import 'ui/screens/chat_detail_screen.dart';
import 'ui/screens/private_chat_detail_screen.dart';
import 'ui/screens/new_private_chat_screen.dart';
import 'ui/screens/new_group_screen.dart';
import 'ui/screens/media_list_screen.dart';
import 'ui/screens/ratings_screen.dart';
import 'ui/screens/actor_details_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/tv_show_detail_screen.dart';
import 'ui/screens/search_screen.dart';
import 'ui/screens/see_more_screen.dart';
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
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (context) =>
                  LoginScreen(onLoginSuccess: _onLoginSuccess),
            );
          case '/splash':
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
          case '/search':
            return MaterialPageRoute(
              builder: (context) => const SearchScreen(),
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
          case '/profile':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: userId),
            );
          case '/edit_profile':
            return MaterialPageRoute(
              builder: (context) => const EditProfileScreen(),
            );
          case '/add_friend':
            return MaterialPageRoute(
              builder: (context) => const AddFriendScreen(),
            );
          case '/friend_requests':
            return MaterialPageRoute(
              builder: (context) => const FriendRequestsScreen(),
            );
          case '/friends':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => FriendsScreen(userId: userId),
            );
          case '/chat_list':
            return MaterialPageRoute(
              builder: (context) => const ChatListScreen(),
            );
          case '/chat_detail':
            final chatId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ChatDetailScreen(chatId: chatId),
            );
          case '/private_chat_detail':
            final chatId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => PrivateChatDetailScreen(chatId: chatId),
            );
          case '/new_private_chat':
            return MaterialPageRoute(
              builder: (context) => const NewPrivateChatScreen(),
            );
          case '/new_group':
            return MaterialPageRoute(
              builder: (context) => const NewGroupScreen(),
            );
          case '/favorites':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => MediaListScreen(
                title: "Favorites",
                collectionName: "favorites",
                userId: userId,
              ),
            );
          case '/watchlist':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => MediaListScreen(
                title: "Watchlist",
                collectionName: "watchlist",
                userId: userId,
              ),
            );
          case '/watched':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => MediaListScreen(
                title: "Watched",
                collectionName: "watched",
                userId: userId,
              ),
            );
          case '/ratings':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => RatingsScreen(userId: userId),
            );
          case '/actor_details':
            final actorId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => ActorDetailsScreen(actorId: actorId),
            );
          case '/tv_details':
            final tvId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => TvShowDetailScreen(tvId: tvId),
            );
          case '/see_more':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SeeMoreScreen(
                title: args['title'],
                category: args['category'],
              ),
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
