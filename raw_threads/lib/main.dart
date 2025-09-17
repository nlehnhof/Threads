import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'classes/main_classes/app_user.dart';
import 'providers/dance_inventory_provider.dart';
import 'providers/shows_provider.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:raw_threads/providers/assignments_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/providers/issues_provider.dart';
import 'package:raw_threads/providers/repair_provider.dart';
import 'package:raw_threads/account/app_state.dart';

import 'pages/real_pages/home_page.dart';
import 'pages/real_pages/welcome_page.dart';

// Route observer for navigation
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          if (!appState.isInitialized) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          // Not logged in → Welcome
          if (FirebaseAuth.instance.currentUser == null) {
            return const MaterialApp(home: WelcomePage());
          }

          final role = appState.role;
          final adminId = appState.adminId;

          // No role set yet → show WelcomePage
          if (role == null) {
            return const MaterialApp(home: WelcomePage());
          }

          // User but not yet linked → show linking page
          if (role != 'admin' && adminId == null) {
            return const MaterialApp(home: LinkAdminPage());
          }

          // ✅ Providers only built once adminId is available
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => DanceInventoryProvider(adminId: adminId!)..init(),
              ),
              ChangeNotifierProxyProvider<DanceInventoryProvider, ShowsProvider>(
                create: (_) => ShowsProvider(adminId: adminId!),
                update: (_, danceProvider, showsProvider) {
                  showsProvider ??= ShowsProvider(adminId: adminId!);
                  showsProvider.init(danceProvider);
                  return showsProvider;
                },
              ),
              ChangeNotifierProvider(create: (_) => TeamProvider()..init()),
              ChangeNotifierProvider(create: (_) => AssignmentProvider(adminId: adminId!)),
              ChangeNotifierProvider(create: (_) => CostumesProvider(adminId: adminId!)),
              ChangeNotifierProvider(create: (_) => IssuesProvider(adminId: adminId!)..init()),
              ChangeNotifierProvider(create: (_) => RepairProvider(adminId: adminId!)..init()),
            ],
            child: MaterialApp(
              navigatorObservers: [routeObserver],
              title: 'Raw Threads',
              theme: ThemeData(
                primarySwatch: Colors.green,
                scaffoldBackgroundColor: const Color(0xFFEBEFEE),
              ),
              home: HomePage(role: role),
            ),
          );
        },
      ),
    );
  }
}

/// Simple placeholder for unlinked users
class LinkAdminPage extends StatelessWidget {
  const LinkAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link to Admin")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Please enter an Admin Code to link your account."),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: implement linking flow
                // Once linked, update AppState.adminId
              },
              child: const Text("Enter Admin Code"),
            )
          ],
        ),
      ),
    );
  }
}
