import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:raw_threads/pages/repair_builds/issue_menu_page.dart';
import 'package:raw_threads/pages/repair_builds/repair_selection_page.dart';
import 'package:raw_threads/pages/repair_builds/repair_summary_page.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'dart:async';
class RepairPage extends StatefulWidget {
  final String role;
  const RepairPage(this.role, {super.key});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  final _dbRef = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> pendingRepairs = [];
  List<Map<String, dynamic>> completedRepairs = [];

  bool get isAdmin => widget.role == 'admin';

  String? _adminId;
  StreamSubscription<DatabaseEvent>? _repairListener;

  @override
  void initState() {
    super.initState();
    _loadAdminIdAndRepairs();
  }

  Future<void> _loadAdminIdAndRepairs() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (isAdmin) {
      _adminId = user.uid;
    } else {
      final snapshot = await _dbRef.child('users').child(user.uid).child('adminId').get();
      if (snapshot.exists) {
        _adminId = snapshot.value as String?;
      }
    }

    if (_adminId != null) {
      _repairListener =_dbRef.child('repairs').child(_adminId!).onValue.listen((event) {
       final repairsMapRaw = event.snapshot.value;
        if (repairsMapRaw is Map) {
          final pending = <Map<String, dynamic>>[];
          final completed = <Map<String, dynamic>>[];

          repairsMapRaw.forEach((key, value) {
            final repair = Map<String, dynamic>.from(value);
            repair['key'] = key;
            if (repair['completed'] == true) {
              completed.add(repair);
            } else {
              pending.add(repair);
            }
          });

          setState(() {
            pendingRepairs = pending;
            completedRepairs = completed;
          });
        } else {
          setState(() {
            pendingRepairs = [];
            completedRepairs = [];
          });
        }
    });
    }
  }

  @override
  void dispose() {
    _repairListener?.cancel();
    super.dispose();
  }

  Future<void> _loadRepairs() async {
    if (_adminId == null) return;

    final repairsSnapshot = await _dbRef.child('repairs').child(_adminId!).get();

    final pending = <Map<String, dynamic>>[];
    final completed = <Map<String, dynamic>>[];

    if (repairsSnapshot.exists) {
      final repairsMap = Map<String, dynamic>.from(repairsSnapshot.value as Map);

      repairsMap.forEach((key, value) {
        final repair = Map<String, dynamic>.from(value);
        repair['key'] = key;
        if (repair['completed'] == true) {
          completed.add(repair);
        } else {
          pending.add(repair);
        }
      });
    }

    setState(() {
      pendingRepairs = pending;
      completedRepairs = completed;
    });
  }

  Future<void> markAsCompleted(Map<String, dynamic> entry) async {
    if (_adminId == null) return;

    final key = entry['key'] as String?;
    if (key == null) return;

    await _dbRef.child('repairs').child(_adminId!).child(key).update({'completed': true});

    // Update local state
    setState(() {
      pendingRepairs.removeWhere((e) => e['key'] == key);
      entry['completed'] = true;
      completedRepairs.add(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repair Page')),
      endDrawer: Sidebar(role: widget.role),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RepairSelectionPage(widget.role)),
              ).then((_) => _loadRepairs()); // Refresh after returning
            },
            child: const Text('Start Repair'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => IssueMenuPage(role: widget.role)),
              );
            },
            child: const Text('Issue Menu'),
          ),
          const Divider(),
          // Pending Repairs Section
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Pending Repairs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pendingRepairs.length,
              itemBuilder: (context, index) {
                final entry = pendingRepairs[index];
                return ListTile(
                  title: Text('${entry['danceTitle']} - ${entry['costumeTitle']}'),
                  subtitle: Text('Submitted by: ${entry['name']}'),
                  trailing: isAdmin
                      ? ElevatedButton(
                          onPressed: () => markAsCompleted(entry),
                          child: const Text('Completed'),
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepairSummaryPage(
                          role: widget.role,
                          danceTitle: entry['danceTitle'],
                          costumeTitle: entry['costumeTitle'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Completed Repairs Section
          if (completedRepairs.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Completed Repairs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 200, // fixed height so both lists fit
              child: ListView.builder(
                itemCount: completedRepairs.length,
                itemBuilder: (context, index) {
                  final entry = completedRepairs[index];
                  return ListTile(
                    title: Text('${entry['danceTitle']} - ${entry['costumeTitle']}'),
                    subtitle: Text('Submitted by: ${entry['name']}'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RepairSummaryPage(
                            role: widget.role,
                            danceTitle: entry['danceTitle'],
                            costumeTitle: entry['costumeTitle'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
