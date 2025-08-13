import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/shows_provider.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:raw_threads/providers/assignments_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';

import 'firebase_options.dart';
import 'package:raw_threads/pages/real_pages/welcome_page.dart';
import 'package:raw_threads/pages/real_pages/home_page.dart';

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
    final adminId = appState.adminId;
    final role = appState.role;

    if (adminId == null || role == null) {
      return const MaterialApp(home: WelcomePage());
    }

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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Raw Threads',
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFEBEFEE),
        ),
        home: HomePage(role: role),
      ),
    );
  }
}
