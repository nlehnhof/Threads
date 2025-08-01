import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:raw_threads/pages/repair_builds/issue_menu_page.dart';
import 'package:raw_threads/pages/repair_builds/repair_selection_page.dart';
import 'package:raw_threads/pages/repair_builds/repair_summary_page.dart';
import 'package:raw_threads/sidebar/sidebar.dart';

class RepairPage extends StatefulWidget {
  const RepairPage({super.key});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  List<Map<String, dynamic>> pendingRepairs = [];
  List<Map<String, dynamic>> completedRepairs = [];

  @override
  void initState() {
    super.initState();
    loadRepairs();
  }

  Future<void> loadRepairs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('last_repair_'));

    final pending = <Map<String, dynamic>>[];
    final completed = <Map<String, dynamic>>[];

    for (final key in keys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        final data = json.decode(jsonStr);
        final parts = key.replaceFirst('last_repair_', '').split('_');
        final danceId = parts.first;
        final costumeTitle = parts.skip(1).join('_');

        final entry = {
          'key': key,
          'danceId': danceId,
          'danceTitle': data['danceTitle'] ?? 'Unknown Dance',
          'costumeTitle': costumeTitle,
          'name': data['name'] ?? '',
          'completed': data['completed'] ?? false,
        };

        if (entry['completed'] == true) {
          completed.add(entry);
        } else {
          pending.add(entry);
        }
      }
    }

    setState(() {
      pendingRepairs = pending;
      completedRepairs = completed;
    });
  }

  Future<void> markAsCompleted(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(entry['key']);
    if (raw == null) return;

    final data = json.decode(raw);
    data['completed'] = true;

    await prefs.setString(entry['key'], json.encode(data));

    // Update local state
    setState(() {
      pendingRepairs.removeWhere((e) => e['key'] == entry['key']);
      completedRepairs.add(entry..['completed'] = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repair Page')),
      endDrawer: Sidebar(),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RepairSelectionPage()),
              ).then((_) => loadRepairs()); // Refresh after returning
            },
            child: const Text('Start Repair'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IssueMenuPage()),
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
                  trailing: ElevatedButton(
                    onPressed: () => markAsCompleted(entry),
                    child: const Text('Completed'),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RepairSummaryPage(
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
              height: 200, // fix height so both lists fit
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
