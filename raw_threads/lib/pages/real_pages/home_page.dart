import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'package:raw_threads/pages/show_builds/shows_list.dart';
import 'package:raw_threads/pages/show_builds/new_show.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/classes/style_classes/primary_button.dart';
import 'package:raw_threads/services/dance_inventory_service.dart';

class HomePage extends StatefulWidget {
  final String role;
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Shows> _shows = [];
  List<Dances> allDances = [];
  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _loadShows();
    _loadDances();
  }

  Future<void> _loadDances() async {
    await DanceInventoryService.instance.load();
    List<Dances> dances = DanceInventoryService.instance.dances;

    setState(() {
      allDances = dances;
    });

    //   allDances = widget.currentUser.role == UserRole.admin
    //       ? dances
    //       : dances.where((d) => d.ownerUsername == widget.currentUser.adminUsername).toList();
    // });
  }

  Future<void> _loadShows() async {
    final prefs = await SharedPreferences.getInstance();
    final showsString = prefs.getString('shows');
    if (showsString == null) return;

    try {
      final List<dynamic> decoded = jsonDecode(showsString);
      final allShows = decoded.map((json) => Shows.fromJson(json)).toList();

      setState(() {
        _shows.clear();
        _shows.addAll(allShows);
      });
    } catch (e) {
      print('Error decoding shows: $e');
    }
  }

  Future<void> _saveShows() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String showsString = json.encode(_shows.map((show) => show.toJson()).toList());
    await prefs.setString('shows', showsString);
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
    int removedIndex = _shows.indexWhere((s) => s.id == show.id);
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

    return Scaffold(
      backgroundColor: const Color(0xFFEBEFEE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBEFEE),
        title: const Text(
          "Threadline",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Vogun',
            fontWeight: FontWeight.bold,
          ),
        ),
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
      endDrawer: Sidebar(),
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
                shows: _shows,
                onRemoveShow: isAdmin ? _removeShow : null,
                onEditShow: isAdmin ? _editShow : null,
                allDances: allDances,
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
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
