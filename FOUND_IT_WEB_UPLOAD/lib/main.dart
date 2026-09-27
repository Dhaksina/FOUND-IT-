import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/supabase_config.dart';
import 'providers/posts_provider.dart';
import 'providers/locale_provider.dart';
import 'views/main_navigation_screen.dart';
import 'views/splash_screen.dart';
import 'services/appwrite_service.dart';

// Background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with try-catch safety fallback
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    // Set up FCM background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User notification permission status: ${settings.authorizationStatus}');

    // Print token for debugging
    final token = await messaging.getToken();
    print("FCM Registration Token: $token");

    // Automatically sign in anonymously to satisfy Firebase Storage rules
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
        print('Firebase anonymous sign in succeeded.');
      } else {
        print('Firebase user already signed in: ${auth.currentUser!.uid}');
      }
    } catch (authError) {
      print('Firebase Anonymous Auth failed: $authError');
    }
  } catch (e) {
    print('Firebase initialization failed or config files missing: $e');
    print('Running app with simulated in-app notification alerts.');
  }

  final bool hasUrl = SupabaseConfig.supabaseUrl.isNotEmpty && 
                     SupabaseConfig.supabaseUrl != 'YOUR_SUPABASE_URL';
  final bool hasKey = SupabaseConfig.supabaseAnonKey.isNotEmpty && 
                      SupabaseConfig.supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  if (hasUrl && hasKey) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      print('Supabase initialized successfully.');
    } catch (e) {
      print('Supabase initialization failed: $e');
    }
  } else {
    print('Supabase credentials are not configured. Running in Demo/Mock data mode.');
  }

  // Initialize Appwrite Service
  AppwriteService.instance.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale    = ref.watch(localeProvider);
    return MaterialApp(
      title: 'TecFind',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: supportedLanguages.map((l) => Locale(l.code)).toList(),
      
      // Light Mode Theme (Set to Dark Theme by Design)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF4F46E5),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF7C3AED),
          onSecondary: Color(0xFFFFFFFF),
          error: Color(0xFFEF4444),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFF1E293B),
          onSurface: Color(0xFFFFFFFF),
          onSurfaceVariant: Color(0xFFCBD5E1),
          primaryContainer: Color(0x1F4F46E5),
          secondaryContainer: Color(0x1F7C3AED),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: const Color(0xFFFFFFFF),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF7C3AED);
              }
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFF334155);
              }
              return const Color(0xFF4F46E5);
            }),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF),
            backgroundColor: const Color(0xFF1E293B),
            side: const BorderSide(color: Color(0xFF334155), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 65,
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF4F46E5),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return IconThemeData(color: Colors.white.withOpacity(0.6));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);
            }
            return TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12);
          }),
        ),
      ),

      // Dark Mode Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF4F46E5),
          onPrimary: Color(0xFFFFFFFF),
          secondary: Color(0xFF7C3AED),
          onSecondary: Color(0xFFFFFFFF),
          error: Color(0xFFEF4444),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFF1E293B),
          onSurface: Color(0xFFFFFFFF),
          onSurfaceVariant: Color(0xFFCBD5E1),
          primaryContainer: Color(0x1F4F46E5),
          secondaryContainer: Color(0x1F7C3AED),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 2,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: const Color(0xFFFFFFFF),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return const Color(0xFF7C3AED);
              }
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFF334155);
              }
              return const Color(0xFF4F46E5);
            }),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFFFFF),
            backgroundColor: const Color(0xFF1E293B),
            side: const BorderSide(color: Color(0xFF334155), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 65,
          backgroundColor: const Color(0xFF0F172A),
          indicatorColor: const Color(0xFF4F46E5),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return IconThemeData(color: Colors.white.withOpacity(0.6));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);
            }
            return TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12);
          }),
        ),
      ),
      
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
