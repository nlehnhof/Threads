import 'dart:async';
import 'package:flutter/material.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'package:raw_threads/pages/show_builds/shows_list.dart';
import 'package:raw_threads/pages/show_builds/new_show.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';

import 'package:raw_threads/classes/style_classes/primary_button.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:provider/provider.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/shows_provider.dart';

class HomePage extends StatefulWidget {
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _linkedAdminId;
  bool get isAdmin => widget.role == 'admin';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  Future<void> _initUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (isAdmin) {
      _linkedAdminId = currentUser.uid;
    } else {
      final userSnapshot = await FirebaseDatabase.instance
          .ref('users/${currentUser.uid}')
          .get();

      if (userSnapshot.exists &&
          userSnapshot.child('linkedAdminId').value != null) {
        _linkedAdminId = userSnapshot.child('linkedAdminId').value as String;
      } else {
        await _promptAdminLinking();
      }
    }

    if (_linkedAdminId != null) {
      if (mounted) {
        await context.read<ShowsProvider>().init(_linkedAdminId!);
        await context.read<DanceInventoryProvider>().init(_linkedAdminId!);
      }
    }
    if (mounted) {
    setState(() => _loading = false);
    }
  }

  Future<void> _promptAdminLinking() async {
    final controller = TextEditingController();

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
            onPressed: () {
              debugPrint('[DEBUG] Link admin dialog canceled.');
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                final adminCode = controller.text.trim();
                debugPrint('[DEBUG] Admin code entered: "$adminCode"');

                if (adminCode.isEmpty) {
                  debugPrint('[DEBUG] Admin code is empty, aborting linking.');
                  return;
                }

                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  debugPrint('[ERROR] No authenticated user found during linking.');
                  return;
                }
                debugPrint('[DEBUG] Current user UID: ${currentUser.uid}');

                debugPrint('[DEBUG] Fetching admins from database...');
                final adminsSnapshot = await FirebaseDatabase.instance.ref('admins').get();

                if (!adminsSnapshot.exists) {
                  debugPrint('[DEBUG] No admins found in database.');
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('No admins found')),
                  );
                  return;
                }

                debugPrint('[DEBUG] Admins snapshot value: ${adminsSnapshot.value}');
                final adminsMap = Map<String, dynamic>.from(adminsSnapshot.value as Map);

                String? matchedAdminId;

                adminsMap.forEach((key, value) {
                  final adminData = Map<String, dynamic>.from(value);
                  debugPrint('[DEBUG] Checking admin UID: $key with code: ${adminData['admincode']}');
                  if (adminData['admincode'] == adminCode) {
                    matchedAdminId = key;
                  }
                });

                if (matchedAdminId != null) {
                  debugPrint('[DEBUG] Matched admin UID: $matchedAdminId');

                  debugPrint('[DEBUG] Updating user linkedAdminId...');
                  await FirebaseDatabase.instance
                      .ref('users/${currentUser.uid}')
                      .update({'linkedAdminId': matchedAdminId});
                  debugPrint('[DEBUG] User linkedAdminId updated.');

                  _linkedAdminId = matchedAdminId;

                  Navigator.of(ctx).pop();

                  if (mounted) {
                    debugPrint('[DEBUG] Initializing providers with linked admin...');
                    await context.read<ShowsProvider>().init(matchedAdminId!);
                    await context.read<DanceInventoryProvider>().init(matchedAdminId!);
                    setState(() {});
                    debugPrint('[DEBUG] Providers initialized.');
                  }
                } else {
                  debugPrint('[DEBUG] Invalid admin code entered.');
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Invalid Admin Code')),
                  );
                }
              } catch (e, stack) {
                debugPrint('[ERROR] Exception during admin linking: $e');
                debugPrint(stack.toString());
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Error linking to admin')),
                );
              }
            },
            child: const Text("Link"),
          ),
        ],
      ),
    );
  }



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
    final danceProvider = context.watch<DanceInventoryProvider>();
    final showsProvider = context.watch<ShowsProvider>();
  
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEBEFEE),
      appBar: AppBar(
        backgroundColor: myColors.primary,
        title: Row(
          children: [
            Image.asset(
              'assets/threadline_logo.png',
              height: 30,
            ),
            Text(
              "Threadline",
              style: TextStyle(
                color: myColors.secondary,
                fontSize: 16,
                fontFamily: 'Vogun',
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  fontSize: 34,
                  fontFamily: 'Vogun',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ShowsList(
                onRemoveShow: isAdmin ? _removeShow : null,
                onEditShow: isAdmin ? _editShow : null,
                allDances: danceProvider.dances,
                isAdmin: isAdmin,
                shows: showsProvider.shows,
              ),
            ),
            if (isAdmin)
              PrimaryButton(
                onPressed: _openAddShowOverlay,
                label: 'Add Show',
                color: const Color(0xFF6A8071),
                color2: Colors.white,
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
