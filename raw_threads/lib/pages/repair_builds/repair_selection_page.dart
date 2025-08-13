import 'package:flutter/material.dart';
import 'package:raw_threads/account/app_state.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/pages/repair_builds/repair_details_page.dart';

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

  bool get isAdmin => widget.role == 'admin';

  Future<void> _loadCostumes() async {
    final adminId = context.read<AppState>().adminId;
    if (adminId != null && selectedDance != null && selectedGender != null) {
      // Properly init costumesProvider with danceId and gender
      await context
          .read<CostumesProvider>()
          .init(danceId: selectedDance!.id, gender: selectedGender!);

      setState(() {
        selectedCostume = null; // reset costume selection on dance/gender change
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final danceProvider = context.watch<DanceInventoryProvider>();
    final dances = danceProvider.dances;

    final costumesProvider = context.watch<CostumesProvider>();
    final costumesList = costumesProvider.costumes;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Dance and Costume')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<Dances>(
              isExpanded: true,
              hint: const Text('Select Dance'),
              value: selectedDance,
              onChanged: (Dances? newValue) async {
                setState(() {
                  selectedDance = newValue;
                  selectedGender = null;
                  selectedCostume = null;
                });
                // Only load costumes if gender already selected
                if (newValue != null && selectedGender != null) {
                  await _loadCostumes();
                }
              },
              items: dances.map((dance) {
                return DropdownMenuItem(
                  value: dance,
                  child: Text(dance.title),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (selectedDance != null)
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select Gender'),
                value: selectedGender,
                onChanged: (String? newValue) async {
                  setState(() {
                    selectedGender = newValue;
                    selectedCostume = null;
                  });
                  // Load costumes only if dance is selected
                  if (selectedDance != null && newValue != null) {
                    await _loadCostumes();
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'Men', child: Text('Men')),
                  DropdownMenuItem(value: 'Women', child: Text('Women')),
                ],
              ),
            const SizedBox(height: 16),
            if (selectedGender != null)
              costumesList.isNotEmpty
                  ? DropdownButton<CostumePiece>(
                      isExpanded: true,
                      hint: const Text('Select Costume Piece'),
                      value: selectedCostume,
                      onChanged: (CostumePiece? newValue) {
                        setState(() {
                          selectedCostume = newValue;
                        });
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
                            costume: selectedCostume!,
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
