import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart';
import 'package:raw_threads/services/dance_inventory_service.dart';
import 'repair_details_page.dart';

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

  @override
  void initState() {
    super.initState();
    DanceInventoryService.instance.load().then((_) => setState(() {}));
  }

  List<CostumePiece> get selectedCostumeList {
    if (selectedDance == null || selectedGender == null) return [];
    return selectedGender == 'Men'
        ? selectedDance!.costumesMen
        : selectedDance!.costumesWomen;
  }

  @override
  Widget build(BuildContext context) {
    final dances = DanceInventoryService.instance.dances;

    return Scaffold(
      appBar: AppBar(title: const Text('Select Dance and Costume')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<Dances>(
              hint: const Text('Select Dance'),
              value: selectedDance,
              onChanged: (Dances? newValue) {
                setState(() {
                  selectedDance = newValue;
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
            if (selectedDance != null)
              DropdownButton<String>(
                hint: const Text('Select Gender'),
                value: selectedGender,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGender = newValue;
                    selectedCostume = null;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'Men', child: Text('Men')),
                  DropdownMenuItem(value: 'Women', child: Text('Women')),
                ],
              ),
            const SizedBox(height: 16),
            if (selectedGender != null)
              selectedCostumeList.isNotEmpty
                  ? DropdownButton<CostumePiece>(
                      hint: const Text('Select Costume Piece'),
                      value: selectedCostume,
                      onChanged: (CostumePiece? newValue) {
                        setState(() {
                          selectedCostume = newValue;
                        });
                      },
                      items: selectedCostumeList.map((piece) {
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
