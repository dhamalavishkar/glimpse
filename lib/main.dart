import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'services/database_service.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed (likely missing google-services.json). Error: $e");
  }
  
  runApp(const LocketCloneApp());
}

class LocketCloneApp extends StatelessWidget {
  const LocketCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glimpse',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthStateWrapper(),
      routes: {
        '/camera': (context) => const CameraScreen(),
        '/feed': (context) => const FeedScreen(),
        '/friends': (context) => const FriendsScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}

class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: DatabaseService.getUser(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.amber)));
              }
              
              if (userSnapshot.hasData && userSnapshot.data?.username != null) {
                return const CameraScreen();
              }
              
              return const ProfileScreen();
            },
          );
        }
        
        return const AuthScreen();
      },
    );
  }
}
