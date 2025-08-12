import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:raw_threads/providers/app_context_provider.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/shows_provider.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/providers/assignments_provider.dart';

import 'firebase_options.dart';
import 'package:raw_threads/pages/real_pages/welcome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(create: (_) => AppContextProvider(),
    child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appContext = context.watch<AppContextProvider>();

    if (!appContext.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DanceInventoryProvider()),
        ChangeNotifierProvider(create: (_) => ShowsProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => CostumesProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
      ],
      child: MaterialApp(
        title: 'Raw Threads',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
        ),
        home: const WelcomePage(),
      ),
    );
  }
}
