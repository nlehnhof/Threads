import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:raw_threads/classes/main_classes/issues.dart';

class IssuesProvider extends ChangeNotifier {
  final String adminId;
  final Map<String, Issues> _issuesMap = {};
  StreamSubscription<DatabaseEvent>? _issuesSubscription;

  IssuesProvider({required this.adminId});

  List<Issues> get allIssues => _issuesMap.values.toList();
  Issues? getIssueById(String id) => _issuesMap[id];

  /// Initialize Firebase listener
  Future<void> init() async {
    await _issuesSubscription?.cancel();

    // Initial load
    await _loadFromFirebase();

    // Live updates
    _issuesSubscription = FirebaseDatabase.instance
        .ref('admins/$adminId/issues')
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      _issuesMap.clear();
      if (data != null) {
        data.forEach((key, value) {
          final issue = Issues.fromJson(Map<String, dynamic>.from(value));
          _issuesMap[issue.id] = issue;
        });
      }

      _saveLocally();
      notifyListeners();
    });
  }

  /// Load data once from Firebase
  Future<void> _loadFromFirebase() async {
    final snapshot =
        await FirebaseDatabase.instance.ref('admins/$adminId/issues').get();

    _issuesMap.clear();
    if (snapshot.exists) {
      final issueMap = Map<String, dynamic>.from(snapshot.value as Map);
      issueMap.forEach((key, value) {
        final issue = Issues.fromJson(Map<String, dynamic>.from(value));
        _issuesMap[issue.id] = issue;
      });
    }

    _saveLocally();
    notifyListeners();
  }

  /// Add issue
  Future<void> add(Issues issue) async {
    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/issues/${issue.id}');
    await ref.set(issue.toJson());

    _issuesMap[issue.id] = issue;
    await _saveLocally();
    notifyListeners();
  }

  /// Update issue
  Future<void> update(Issues updated) async {
    final ref = FirebaseDatabase.instance
        .ref('admins/$adminId/issues/${updated.id}');
    await ref.set(updated.toJson());
  
    _issuesMap[updated.id] = updated;
    await _saveLocally();
    notifyListeners();
  }

  /// Delete issue
  Future<void> delete(String id) async {
    await FirebaseDatabase.instance
        .ref('admins/$adminId/issues/$id')
        .remove();
    _issuesMap.remove(id);
    _saveLocally();
    notifyListeners();
  }

  /// Local caching
  Future<void> _saveLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'issues_cache_$adminId',
      json.encode(_issuesMap.values.map((e) => e.toJson()).toList()),
    );
  }

  /// Load cached data without network
  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('issues_cache_$adminId');
    if (data != null) {
      final decoded = json.decode(data) as List;
      _issuesMap.clear();
      for (var e in decoded) {
        final issue = Issues.fromJson(e);
        _issuesMap[issue.id] = issue;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _issuesSubscription?.cancel();
    super.dispose();
  }
}
