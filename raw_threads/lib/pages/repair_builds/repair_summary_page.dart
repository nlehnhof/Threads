import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/providers/costume_provider.dart';
import 'package:raw_threads/providers/repair_provider.dart';
import 'package:raw_threads/classes/main_classes/repairs.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';
import 'package:raw_threads/pages/real_pages/repair_page.dart';
import 'package:raw_threads/classes/style_classes/sewing_loader.dart';

class RepairSummaryPage extends StatelessWidget {
  final Repairs repair;
  final String role;

  const RepairSummaryPage({
    super.key,
    required this.repair,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  Future<void> _markRepairComplete(BuildContext context) async {
    if (!isAdmin) return;
    final provider = context.read<RepairProvider>();
    final completedRepair = repair.copyWith(completed: true);
    await provider.update(completedRepair);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final costumesProvider = context.read<CostumesProvider>();

    // Initialize provider for this repair's dance and gender
    final initFuture = costumesProvider.init(
      danceId: repair.danceId,
      gender: repair.gender,
    );

    return FutureBuilder(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Show loader while initializing
          return Scaffold(
            backgroundColor: myColors.secondary,
            appBar: AppBar(
              backgroundColor: myColors.secondary,
              elevation: 0,
              title: const Text(
                'Repair Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vogun',
                  fontSize: 24,
                ),
              ),
            ),
            body: const Center(child: CustomLoader()),
          );
        }

        // Once initialized, get the costume
        // final costume = costumesProvider.getCostumeById(repair.costumeId);
        // final title = costume?.title ?? "Unknown Costume";

        return Scaffold(
          backgroundColor: myColors.secondary,
          appBar: AppBar(
            backgroundColor: myColors.secondary,
            elevation: 0,
            title: Text(
              '${repair.name} - ${repair.costumeTitle} Repair',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Vogun',
                fontSize: 24,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RepairPage(role: role)),
                  );
                },
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRepairDetailsCard(),
                const SizedBox(height: 16),
                if (repair.issues.isNotEmpty) _buildIssuesCard(),
                const SizedBox(height: 16),
                if (repair.photoPath != null && repair.photoPath!.isNotEmpty)
                  _buildRepairPhoto(),
                const SizedBox(height: 24),
                if (isAdmin && !repair.completed) _buildCompleteButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRepairDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Repair Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow("Name", repair.name),
            _buildDetailRow("Team", repair.team),
            _buildDetailRow("Email", repair.email),
            _buildDetailRow("Costume #", repair.number),
            _buildDetailRow("Comments", repair.comments),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Selected Issues",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: repair.issues.map((e) {
                return ListTile(
                  leading: e.image != null && e.image!.isNotEmpty
                      ? Image.network(
                          e.image!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.check, color: Colors.grey),
                  title: Text(e.title),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepairPhoto() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        repair.photoPath!,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 220,
            child: Center(child: Icon(Icons.broken_image)),
          );
        },
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: myColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
        onPressed: () => _markRepairComplete(context),
        child: const Text(
          'Mark Repair Complete',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Expanded(
            child: Text(value?.isNotEmpty == true ? value! : "Not Given",
                style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
