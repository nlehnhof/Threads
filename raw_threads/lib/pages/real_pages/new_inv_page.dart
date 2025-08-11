import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/pages/dance_builds/generic_dance_page.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/dance_builds/add_generic_dialog.dart';

import 'package:provider/provider.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';

class DanceInventoryPage extends StatefulWidget {
  final String role;
  const DanceInventoryPage({super.key, required this.role});

  @override
  State<DanceInventoryPage> createState() => _DanceInventoryPageState();
}

class _DanceInventoryPageState extends State<DanceInventoryPage> {
  String searchQuery = "";
  bool sortByDance = true;
  bool get isAdmin => widget.role == 'admin';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DanceInventoryProvider>();
    final allDances = provider.dances;
    
    List<Dances> filtered = allDances
        .where((dance) =>
          dance.title.toLowerCase().contains(searchQuery) ||
          dance.country.toLowerCase().contains(searchQuery))
        .toList();

    filtered.sort((a, b) => sortByDance 
        ? a.title.compareTo(b.title) 
        : a.country.compareTo(b.country));

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(
        title: const Text("Inventory"),
        centerTitle: true,
        actions: [
          if (widget.role == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AddGenericDialog(
                onSubmit: (dance) async {
                  try {
                    await provider.add(dance);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add dance: $e')),
                    );
                  }
                },
                ),
              ),
            )
          ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(hintText: "Search"),
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          ToggleButtons(
            isSelected: [sortByDance, !sortByDance],
            onPressed: (index) => setState(() => sortByDance = index == 0),
            constraints: const BoxConstraints(minWidth: 180.0, minHeight: 40.0),
            textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            fillColor: const Color.fromARGB(255, 133, 167, 185),
            borderRadius: BorderRadius.circular(14.0),
            borderWidth: 2.0,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Dance", style: TextStyle(color: Colors.black)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text("Country", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final dance = filtered[index];
                return ListTile(
                  title: Text(dance.title),
                  subtitle: Text(dance.country),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GenericDancePage(
                          role: widget.role,
                          dance: dance,
                          onDelete: (danceToDelete) async {
                            await provider.delete(danceToDelete.id);
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
