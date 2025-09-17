import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/shows_provider.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'package:raw_threads/pages/show_builds/shows_list.dart';
import 'package:raw_threads/pages/show_builds/new_show.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/classes/style_classes/primary_button.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

class HomePage extends StatefulWidget {
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool get isAdmin => widget.role == 'admin';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Schedule after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserData();
    });
  }

Future<void> _initUserData({bool forceReload = false}) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  final appState = context.read<AppState>();
  String? targetAdminId;

  if (isAdmin) {
    targetAdminId = currentUser.uid;
  } else {
    final userSnap =
        await FirebaseDatabase.instance.ref('users/${currentUser.uid}').get();
    targetAdminId = userSnap.exists &&
            userSnap.child('linkedAdminId').value != null
        ? userSnap.child('linkedAdminId').value as String
        : null;

    if (targetAdminId == null) {
      appState.setAdminId(null);
      await _promptAdminLinking(); // wait until user links to admin
      return; // providers will re-init after linking
    }
  }

  // Update AppState
  appState.setAdminId(targetAdminId);

  // Initialize dependent providers safely
  Future.microtask(() async {
    if (!mounted) return;

    final danceProvider = context.read<DanceInventoryProvider>();
    if (!danceProvider.isInitialized || forceReload) {
      await danceProvider.init();
    }

    final showsProvider = context.read<ShowsProvider>();
    if (!showsProvider.isInitialized || forceReload) {
      await showsProvider.init(danceProvider);
    }

    if (mounted) setState(() {});
  });
}

Future<void> _promptAdminLinking() async {
  final controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text("Link to Admin"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: "Enter Admin Code"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            final adminCode = controller.text.trim();
            if (adminCode.isEmpty) return;

            try {
              final adminsSnap =
                  await FirebaseDatabase.instance.ref('admins').get();
              if (!adminsSnap.exists) return;

              String? matchedAdminId;
              for (final adminEntry in adminsSnap.children) {
                if (adminEntry.child('admincode').value == adminCode) {
                  matchedAdminId = adminEntry.key;
                  break;
                }
              }

              if (matchedAdminId != null) {
                await FirebaseDatabase.instance
                    .ref('users/${currentUser.uid}')
                    .update({'linkedAdminId': matchedAdminId});

                if (mounted) Navigator.of(ctx).pop();

                // 🔑 Re-init providers with the new adminId
                await _initUserData(forceReload: true);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Successfully linked to admin!')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid Admin Code')),
                  );
                }
              }
            } catch (e) {
              debugPrint('Error linking admin: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error linking to admin')),
                );
              }
            }
          },
          child: const Text("Link"),
        ),
      ],
    ),
  );
}

  // --- UI methods (unchanged) ---
  void _openAddShowOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: NewShow(
            onSaveShow: (show) async {
              await context.read<ShowsProvider>().addShow(show);
            },
          ),
        ),
      ),
    );
  }

  void _editShow(Shows updatedShow) async {
    await context.read<ShowsProvider>().updateShow(updatedShow);
  }

  void _removeShow(Shows show) async {
    final showsProvider = context.read<ShowsProvider>();
    await showsProvider.removeShow(show.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Show removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await showsProvider.addShow(show);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final adminId = appState.adminId;

    final danceProvider = context.watch<DanceInventoryProvider>();
    final showsProvider = context.watch<ShowsProvider>();

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColors.secondary,
        title: Row(
          children: [
            Image.asset('assets/logotype_green.png', height: 20),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Sidebar(role: widget.role),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "Home",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontFamily: 'Vogun',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: adminId == null
                  ? const Center(
                      child: Text('Please link your account to an admin.'),
                    )
                  : ShowsList(
                      onRemoveShow: isAdmin ? _removeShow : null,
                      onEditShow: isAdmin ? _editShow : null,
                      allDances: danceProvider.dances,
                      shows: showsProvider.shows,
                      isAdmin: isAdmin,
                    ),
            ),
            if (isAdmin)
              PrimaryButton(
                onPressed: _openAddShowOverlay,
                label: 'Add Show',
                color: const Color(0xFF6A8071),
                color2: Colors.white,
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
