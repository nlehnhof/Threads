import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
import 'package:raw_threads/pages/repair_builds/issue_menu_page.dart';
import 'package:raw_threads/pages/repair_builds/repair_selection_page.dart';
import 'package:raw_threads/pages/repair_builds/repair_summary_page.dart';
import 'package:raw_threads/providers/repair_provider.dart';
import 'package:raw_threads/classes/main_classes/repairs.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/real_pages/route_observer.dart'; // global observer

class RepairPage extends StatefulWidget {
  final String role;
  const RepairPage({super.key, required this.role});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> with RouteAware {
  bool get isAdmin => widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RepairProvider>().init(); // initial load
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // called when page is pushed
    context.read<RepairProvider>().init();
  }

  @override
  void didPopNext() {
    // called when navigating back to this page
    context.read<RepairProvider>().init();
  }

  Future<void> markAsCompleted(Repairs repair) async {
    final updatedRepair = repair.copyWith(completed: true);
    await context.read<RepairProvider>().update(updatedRepair);
  }

  Future<void> deleteRepair(BuildContext context, Repairs repair) async {
    final provider = context.read<RepairProvider>();
    await provider.delete(repair.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Deleted '${repair.costumeTitle} | ${repair.name}'"),
        action: SnackBarAction(
          label: "UNDO",
          onPressed: () {
            provider.add(repair); // restore
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: myColors.secondary,
        title: Image.asset('assets/logotype_green.png', height: 20),
        centerTitle: false,
        elevation: 0,
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
      body: Consumer<RepairProvider>(
        builder: (context, provider, _) {
          final pendingRepairs =
              provider.repairs.where((r) => !r.completed).toList();
          final completedRepairs =
              provider.repairs.where((r) => r.completed).toList();

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Repairs',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Vogun',
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isAdmin)
                          TextButton(
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => IssueMenuPage()),
                              );
                            },
                            child: Text('Issue Menu',
                                style: TextStyle(
                                    color: myColors.primary, fontSize: 14)),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (pendingRepairs.isEmpty)
                            const Center(child: Text('No pending repairs'))
                          else ...pendingRepairs.map((repair) {
                            final tile = Card(
                              child: ListTile(
                                title:
                                    Text('${repair.costumeTitle} | ${repair.name}'),
                                trailing: isAdmin
                                    ? TextButton(
                                        onPressed: () =>
                                            markAsCompleted(repair),
                                        child: const Text('Complete'),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RepairSummaryPage(
                                          repair: repair, role: widget.role),
                                    ),
                                  );
                                },
                              ),
                            );

                            return isAdmin
                                ? Dismissible(
                                    key: Key(repair.id),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerLeft,
                                      padding:
                                          const EdgeInsets.only(left: 20),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    secondaryBackground: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding:
                                          const EdgeInsets.only(right: 20),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    onDismissed: (_) =>
                                        deleteRepair(context, repair),
                                    child: tile,
                                  )
                                : tile;
                          }),
                          if (completedRepairs.isNotEmpty) ...[
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Completed Repairs',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ),
                            ...completedRepairs.map((repair) {
                              final tile = Card(
                                color: myColors.disabled,
                                child: ListTile(
                                  title: Text(
                                    '${repair.costumeTitle} | ${repair.name}',
                                    style: const TextStyle(
                                        color: Color(0xFF6A8071)),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RepairSummaryPage(
                                            repair: repair,
                                            role: widget.role),
                                      ),
                                    );
                                  },
                                ),
                              );

                              return isAdmin
                                  ? Dismissible(
                                      key: Key(repair.id),
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerLeft,
                                        padding:
                                            const EdgeInsets.only(left: 20),
                                        child: const Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                      secondaryBackground: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        child: const Icon(Icons.delete,
                                            color: Colors.white),
                                      ),
                                      onDismissed: (_) =>
                                          deleteRepair(context, repair),
                                      child: tile,
                                    )
                                  : tile;
                            }),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                RepairSelectionPage(widget.role)),
                      );
                    },
                    child: const Text(
                      'Start Repair',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
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
