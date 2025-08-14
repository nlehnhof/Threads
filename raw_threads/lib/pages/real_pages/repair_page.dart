import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'package:raw_threads/pages/repair_builds/issue_menu_page.dart';
import 'package:raw_threads/pages/repair_builds/repair_selection_page.dart';
import 'package:raw_threads/pages/repair_builds/repair_summary_page.dart';
import 'package:raw_threads/providers/repair_provider.dart';
import 'package:raw_threads/classes/main_classes/repairs.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

class RepairPage extends StatefulWidget {
  final String role;
  const RepairPage({super.key, required this.role});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RepairProvider>().init();
    });
  }

  Future<void> markAsCompleted(Repairs repair) async {
    final updatedRepair = repair.copyWith(completed: true);
    await context.read<RepairProvider>().update(updatedRepair);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        backgroundColor: myColors.secondary,
        title: Row(
          children: [
            Image.asset('assets/threadline_logo.png', height: 30),
            const SizedBox(width: 8),
            Text(
              "Threadline",
              style: TextStyle(
                color: myColors.primary,
                fontSize: 25,
                fontFamily: 'Vogun',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => IssueMenuPage()),
              );
            },
            child: Text('Issue Menu', style: TextStyle(color: myColors.primary)),
          ),
        ],
      ),
      endDrawer: Sidebar(role: widget.role),
      body: Consumer<RepairProvider>(
        builder: (context, provider, _) {
          final pendingRepairs = provider.repairs.where((r) => !r.completed).toList();
          final completedRepairs = provider.repairs.where((r) => r.completed).toList();

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Repairs', 
                      style: TextStyle(
                        color: Colors.black, fontFamily: 'Vogun', fontSize: 30, fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                  child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (pendingRepairs.isEmpty)
                        const Center(child: Text('No pending repairs'))
                      else ...pendingRepairs.map((repair) {
                        return Card(
                          child: ListTile(
                            title: Text('${repair.name} - ${repair.issues}'),
                            trailing: widget.role == 'admin'
                                ? TextButton(
                                    onPressed: () => markAsCompleted(repair),
                                    child: const Text('Complete'),
                                  )
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RepairSummaryPage(repair: repair, role: widget.role),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                      if (completedRepairs.isNotEmpty) ...[
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Completed Repairs',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        ...completedRepairs.map((repair) {
                          return Card(
                            color: myColors.disabled,
                            child: ListTile(
                              title: Text('${repair.name} - ${repair.costumeTitle}', style: TextStyle(color: Color(0xFF6A8071))),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RepairSummaryPage(repair: repair, role: widget.role),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                  ),
                ),
              ],
            ),
              // Bottom Start Repair Button
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: myColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RepairSelectionPage(widget.role)),
                      );
                    },
                    child: const Text(
                      'Start Repair',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
