import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/pages/repair_builds/repair_details_page.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

class RepairSelectionPage extends StatefulWidget {
  final String role;
  const RepairSelectionPage(this.role, {super.key});

  @override
  State<RepairSelectionPage> createState() => _RepairSelectionPageState();
}

class _RepairSelectionPageState extends State<RepairSelectionPage> {
  Dances? selectedDance;
  String? selectedGender;
  CostumePiece? selectedCostume;
  bool loadingCostumes = false;

  bool get isAdmin => widget.role == 'admin';

  Future<void> _loadCostumes() async {
    if (selectedDance == null || selectedGender == null) return;

    setState(() => loadingCostumes = true);

    final adminId = context.read<AppState>().adminId;
    if (adminId != null) {
      await context
          .read<CostumesProvider>()
          .init(danceId: selectedDance!.id, gender: selectedGender!);
    }

    setState(() {
      selectedCostume = null; // reset selection
      loadingCostumes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final danceProvider = context.watch<DanceInventoryProvider>();
    final dances = danceProvider.dances;

    final costumesProvider = context.watch<CostumesProvider>();
    final costumesList = costumesProvider.costumes;

    return Scaffold(
      backgroundColor: myColors.secondary,
      appBar: AppBar(title: const Text('Select Dance and Costume')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dance selection
            DropdownButton<Dances>(
              isExpanded: true,
              hint: Text('Select Dance', style: TextStyle(color: myColors.secondary)),
              value: selectedDance,
              onChanged: (Dances? newDance) async {
                setState(() {
                  selectedDance = newDance;
                  selectedGender = null;
                  selectedCostume = null;
                });
              },
              items: dances.map((dance) {
                return DropdownMenuItem(
                  value: dance,
                  child: Text(dance.title),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Gender selection
            if (selectedDance != null)
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select Gender'),
                value: selectedGender,
                onChanged: (String? newGender) async {
                  setState(() {
                    selectedGender = newGender;
                    selectedCostume = null;
                  });
                  await _loadCostumes();
                },
                items: const [
                  DropdownMenuItem(value: 'Men', child: Text('Men')),
                  DropdownMenuItem(value: 'Women', child: Text('Women')),
                ],
              ),
            const SizedBox(height: 16),

            // Costume selection
            if (selectedGender != null)
              loadingCostumes
                  ? const Center(child: CircularProgressIndicator())
                  : costumesList.isNotEmpty
                      ? DropdownButton<CostumePiece>(
                          isExpanded: true,
                          hint: const Text('Select Costume Piece'),
                          value: selectedCostume,
                          onChanged: (CostumePiece? newCostume) {
                              // final costume = costumesProvider.getCostumeById(newCostume!.id);
                              // final costumeTitle = costume.title;
                            setState(() {
                              selectedCostume = newCostume;
                            }  
                            );
                          },
                          items: costumesList.map((piece) {
                            return DropdownMenuItem(
                              value: piece,
                              child: Text(piece.title),
                            );
                          }).toList(),
                        )
                      : const Text('No costume pieces available for this gender'),

            const Spacer(),

            // Next button
            ElevatedButton(
              onPressed: (selectedDance != null &&
                      selectedGender != null &&
                      selectedCostume != null)
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RepairDetailsPage(
                            widget.role,
                            dance: selectedDance!,
                            gender: selectedGender!,
                            costume: selectedCostume!,
                            costumeTitle: selectedCostume!.title,
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
