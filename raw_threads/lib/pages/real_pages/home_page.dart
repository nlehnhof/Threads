import 'dart:async';
import 'package:raw_threads/services/costume_inventory_service.dart';
import 'package:flutter/material.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'package:raw_threads/pages/show_builds/shows_list.dart';
import 'package:raw_threads/pages/show_builds/new_show.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/classes/style_classes/primary_button.dart';
import 'package:raw_threads/services/dance_inventory_service.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _linkedAdminId;
  List<Shows> _shows = [];
  List<Dances> allDances = [];
  bool get isAdmin => widget.role == 'admin';
  bool _loading = true;

  StreamSubscription<DatabaseEvent>? _showsSubscription;
  StreamSubscription<DatabaseEvent>? _dancesSubscription;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  @override
  void dispose() {
    _showsSubscription?.cancel();
    _dancesSubscription?.cancel();
    super.dispose();
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
      _startRealtimeListeners(_linkedAdminId!);
    }

    setState(() => _loading = false);
  }

  void _startRealtimeListeners(String adminId) {
    // Cancel old listeners if any
    _showsSubscription?.cancel();
    _dancesSubscription?.cancel();

    _showsSubscription = FirebaseDatabase.instance
        .ref('admins/$adminId/shows')
        .onValue
        .listen((event) {
      final showsMap = event.snapshot.value as Map<dynamic, dynamic>?;

      if (showsMap != null) {
        final loadedShows = showsMap.entries
            .map((e) => Shows.fromJson(Map<String, dynamic>.from(e.value)))
            .toList();
        setState(() {
          _shows = loadedShows;
        });
      } else {
        setState(() {
          _shows = [];
        });
      }
    });

    _dancesSubscription = FirebaseDatabase.instance
        .ref('admins/$adminId/dances')
        .onValue
        .listen((event) {
      final dancesMap = event.snapshot.value as Map<dynamic, dynamic>?;

      if (dancesMap != null) {
        final loadedDances = dancesMap.entries
            .map((e) => Dances.fromJson(Map<String, dynamic>.from(e.value)))
            .toList();
        setState(() {
          allDances = loadedDances;
        });
      } else {
        setState(() {
          allDances = [];
        });
      }
    });
  }

  Future<void> _loadStaticData(String adminId) async {
    final showSnapshot =
        await FirebaseDatabase.instance.ref('admins/$adminId/shows').get();
    final danceSnapshot =
        await FirebaseDatabase.instance.ref('admins/$adminId/dances').get();

    List<Shows> loadedShows = [];
    if (showSnapshot.exists) {
      final showsMap = Map<String, dynamic>.from(showSnapshot.value as Map);
      loadedShows = showsMap.entries
          .map((entry) =>
              Shows.fromJson(Map<String, dynamic>.from(entry.value)))
          .toList();
    }

    List<Dances> loadedDances = [];
    if (danceSnapshot.exists) {
      final dancesMap = Map<String, dynamic>.from(danceSnapshot.value as Map);
      loadedDances = dancesMap.entries
          .map((entry) =>
              Dances.fromJson(Map<String, dynamic>.from(entry.value)))
          .toList();
    }

    setState(() {
      _shows = loadedShows;
      allDances = loadedDances;
    });
  }

  Future<void> _promptAdminLinking() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Link to Admin"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter Admin UID",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final adminId = controller.text.trim();
              if (adminId.isNotEmpty) {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  await FirebaseDatabase.instance
                      .ref('users/${currentUser.uid}')
                      .update({'linkedAdminId': adminId});
                  _linkedAdminId = adminId;
                  Navigator.of(ctx).pop();
                  // Start listeners & load data after linking
                  _startRealtimeListeners(adminId);
                  await DanceInventoryService.instance.load();
                  await _loadStaticData(adminId);
                  setState(() {});
                }
              }
            },
            child: const Text("Link"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveShows() async {
    if (!isAdmin || _linkedAdminId == null) return;

    final showsMap = {
      for (var show in _shows) show.id: show.toJson(),
    };

    await FirebaseDatabase.instance
        .ref('admins/$_linkedAdminId/shows')
        .set(showsMap);
  }

  void _openAddShowOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: NewShow(onSaveShow: _addShow),
        ),
      ),
    );
  }

  void _editShow(Shows updatedShow) {
    setState(() {
      final index = _shows.indexWhere((s) => s.id == updatedShow.id);
      if (index != -1) {
        _shows[index] = updatedShow;
      }
    });
    _saveShows();
  }

  void _addShow(Shows newShow) {
    setState(() {
      if (!_shows.any((show) => show.id == newShow.id)) {
        _shows.add(newShow);
      }
    });
    _saveShows();
  }

  void _removeShow(Shows show) {
    final removedIndex = _shows.indexWhere((s) => s.id == show.id);
    setState(() {
      _shows.removeAt(removedIndex);
    });
    _saveShows();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Show removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _shows.insert(removedIndex, show);
            });
            _saveShows();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                allDances: allDances,
                isAdmin: isAdmin,
                shows: _shows,
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
