import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'services/database_service.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Supabase.initialize(
      url: 'https://joiqwzzlushasopbypcg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvaXF3enpsdXNoYXNvcGJ5cGNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3MjQ4NzcsImV4cCI6MjA5ODMwMDg3N30.JP5KFtVX1XU26AvkWYIH4_jVnWbJVpPqjWC0-Wl9KUk',
    );
  } catch (e) {
    debugPrint("Supabase init failed. Error: $e");
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
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class AuthStateWrapper extends StatelessWidget {
  const AuthStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final session = snapshot.data?.session;
        if (session != null && session.user != null) {
          return FutureBuilder<UserModel?>(
            future: DatabaseService.getUser(session.user.id),
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
