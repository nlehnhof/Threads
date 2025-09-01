import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/shows_provider.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:raw_threads/providers/assignments_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/providers/issues_provider.dart';
import 'package:raw_threads/providers/repair_provider.dart';

import 'package:raw_threads/pages/real_pages/welcome_page.dart';
import 'package:raw_threads/pages/real_pages/home_page.dart';
import 'package:raw_threads/pages/real_pages/route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading spinner while waiting for Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            debugShowCheckedModeBanner: false,
          );
        }

        final user = snapshot.data;

        // User is logged out → show WelcomePage
        if (user == null) {
          return const MaterialApp(home: WelcomePage(), debugShowCheckedModeBanner: false,);
        }

        // Initialize AppState if not yet initialized
        if (!appState.isInitialized) {
          // Fire-and-forget; UI will rebuild when AppState notifies
          appState.initialize(uid: user.uid);
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            debugShowCheckedModeBanner: false,
          );
        }

        // AppState initialized → check adminId and role
        final adminId = appState.adminId;
        final role = appState.role;

        if (adminId == null || role == null) {
          // Initialization completed but missing data → fallback
          return const MaterialApp(home: WelcomePage(), debugShowCheckedModeBanner: false,);
        }

        // MultiProvider wraps all app data providers
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<CostumesProvider>(
              create: (_) => CostumesProvider(adminId: adminId),
            ),
            ChangeNotifierProvider<DanceInventoryProvider>(
              create: (_) => DanceInventoryProvider(adminId: adminId)..init(),
            ),
            ChangeNotifierProvider<ShowsProvider>(
              create: (_) => ShowsProvider(adminId: adminId)..init(),
            ),
            ChangeNotifierProvider<TeamProvider>(
              create: (_) => TeamProvider(adminId: adminId)..init(),
            ),
            ChangeNotifierProvider<AssignmentProvider>(
              create: (_) => AssignmentProvider(adminId: adminId),
            ),
            ChangeNotifierProvider<IssuesProvider>(
              create: (_) => IssuesProvider(adminId: adminId)..init(),
            ),
            ChangeNotifierProvider<RepairProvider>(
              create: (_) => RepairProvider(adminId: adminId)..init(),
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [routeObserver],
            debugShowCheckedModeBanner: false,
            title: 'Raw Threads',
            theme: ThemeData(
              primarySwatch: Colors.green,
              scaffoldBackgroundColor: const Color(0xFFEBEFEE),
            ),
            home: HomePage(role: role),
          ),
        );
      },
    );
  }
}