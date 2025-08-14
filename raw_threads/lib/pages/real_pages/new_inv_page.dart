import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/pages/dance_builds/generic_dance_page.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/dance_builds/add_generic_dialog.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/sidebar/sidebar.dart';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: AppBar(
          backgroundColor: myColors.secondary, // match page background
          elevation: 0, // flat
          centerTitle: true,
          title: const Text(
            "Inventory",
            style: TextStyle(
              fontFamily: 'Vogun',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      ),
      endDrawer: Sidebar(role: widget.role),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // SEARCH BAR
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search dances or countries",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                ),
                const SizedBox(height: 12),
                // TOGGLE BUTTONS
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(16),
                  child: ToggleButtons(
                    isSelected: [sortByDance, !sortByDance],
                    onPressed: (index) =>
                        setState(() => sortByDance = index == 0),
                    borderRadius: BorderRadius.circular(16),
                    fillColor: myColors.selected,
                    selectedColor: Colors.white,
                    color: myColors.primary,
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 16),
                    constraints:
                        const BoxConstraints(minHeight: 40, minWidth: 140),
                    children: const [
                      Text("Dance"),
                      Text("Country"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // DANCE GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 8,
                childAspectRatio: 10/2,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final dance = filtered[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GenericDancePage(
                          role: widget.role,
                          dance: dance,
                          onDelete: (danceToDelete) async {
                            await provider.delete(danceToDelete.id);
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: myColors.completed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dance.title,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: myColors.secondary),
                          ),
                          Text(
                            dance.country,
                            style: TextStyle(
                                fontSize: 18, color: myColors.secondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: myColors.primary,
        foregroundColor: myColors.disabled,
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
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
