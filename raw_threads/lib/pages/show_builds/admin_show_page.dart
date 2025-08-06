import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/pages/show_builds/shows_list.dart';

class AdminShowsPage extends StatefulWidget {
  final bool isAdmin; // you can pass this flag from your auth logic

  const AdminShowsPage({super.key, required this.isAdmin});

  @override
  State<AdminShowsPage> createState() => _AdminShowsPageState();
}

class _AdminShowsPageState extends State<AdminShowsPage> {
  List<Shows> _shows = [];
  List<Dances> _allDances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final adminIdSnap = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId)
        .child('adminId')
        .get();

    // If user has no linked admin, and is admin themself, use their own uid
    final adminId = adminIdSnap.exists && adminIdSnap.value != null
        ? adminIdSnap.value.toString()
        : (widget.isAdmin ? userId : null);

    if (adminId == null) {
      setState(() {
        _loading = false;
      });
      return; // no admin linked and user not admin
    }

    final showsSnap = await FirebaseDatabase.instance
        .ref()
        .child('admins')
        .child(adminId)
        .child('shows')
        .get();

    final dancesSnap = await FirebaseDatabase.instance
        .ref()
        .child('admins')
        .child(adminId)
        .child('dances')
        .get();

    final List<Shows> loadedShows = [];
    if (showsSnap.exists) {
      final rawShows = Map<String, dynamic>.from(showsSnap.value as Map);
      rawShows.forEach((key, value) {
        loadedShows.add(Shows.fromJson(Map<String, dynamic>.from(value)));
      });
    }

    final List<Dances> loadedDances = [];
    if (dancesSnap.exists) {
      final rawDances = Map<String, dynamic>.from(dancesSnap.value as Map);
      rawDances.forEach((key, value) {
        loadedDances.add(Dances.fromJson(Map<String, dynamic>.from(value)));
      });
    }

    setState(() {
      _shows = loadedShows;
      _allDances = loadedDances;
      _loading = false;
    });
  }

  void _removeShow(Shows show) async {
    // remove show locally
    setState(() {
      _shows.removeWhere((s) => s.id == show.id);
    });

    // remove from firebase
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final adminIdSnap = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId!)
        .child('adminId')
        .get();

    final adminId = adminIdSnap.exists && adminIdSnap.value != null
        ? adminIdSnap.value.toString()
        : (widget.isAdmin ? userId : null);

    if (adminId != null) {
      await FirebaseDatabase.instance
          .ref()
          .child('admins')
          .child(adminId)
          .child('shows')
          .child(show.id)
          .remove();
    }
  }

  void _editShow(Shows updatedShow) async {
    final index = _shows.indexWhere((s) => s.id == updatedShow.id);
    if (index != -1) {
      setState(() {
        _shows[index] = updatedShow;
      });
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final adminIdSnap = await FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(userId!)
        .child('adminId')
        .get();

    final adminId = adminIdSnap.exists && adminIdSnap.value != null
        ? adminIdSnap.value.toString()
        : (widget.isAdmin ? userId : null);

    if (adminId != null) {
      await FirebaseDatabase.instance
          .ref()
          .child('admins')
          .child(adminId)
          .child('shows')
          .child(updatedShow.id)
          .set(updatedShow.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ShowsList(
      isAdmin: widget.isAdmin,
      onRemoveShow: _removeShow,
      onEditShow: _editShow,
      allDances: _allDances,
      shows: _shows,
    );
  }
}
