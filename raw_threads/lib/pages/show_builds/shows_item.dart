import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';
import 'package:raw_threads/providers/teams_provider.dart';
import 'package:raw_threads/pages/show_builds/edit_show_page.dart';
import 'package:raw_threads/classes/style_classes/my_colors.dart';

class ShowItem extends StatefulWidget {
  final Shows show;
  final void Function(Shows show)? onEditShow;
  final bool isAdmin;

  const ShowItem({
    required this.show,
    this.onEditShow,
    this.isAdmin = false,
    super.key,
  });

  @override
  State<ShowItem> createState() => _ShowItemState();
}

class _ShowItemState extends State<ShowItem> {
  bool isExpanded = false;

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Vogun',
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(fontSize: 14, fontFamily: 'Vogun'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.show;
    final allDances = context.watch<DanceInventoryProvider>().dances;
    final teamProvider = context.watch<TeamProvider>();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFEFEFE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show Title + Edit button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    show.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      fontFamily: 'Vogun',
                    ),
                  ),
                ),
                if (widget.isAdmin)
                  GestureDetector(
                    onTap: () async {
                      final updatedShow = await Navigator.of(context).push<Shows>(
                        MaterialPageRoute(
                          builder: (ctx) => EditShowPage(
                            show: show,
                            onSave: (updated) {},
                          ),
                        ),
                      );
                      if (updatedShow != null) {
                        widget.onEditShow?.call(updatedShow);
                      }
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Color(0xFF191B1A), fontSize: 15, fontFamily: 'Raleway', height: 0, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Location', show.location),
            _infoRow('Dates', show.dates),
            _infoRow('Tech', show.tech),
            _infoRow('Dress', show.dress),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: const SizedBox(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dances:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Vogun')),
                  if (show.danceIds.isEmpty)
                    const Text('No dances assigned.',
                        style: TextStyle(fontSize: 14, fontFamily: 'Vogun'))
                  else if (allDances.isEmpty)
                    const Text('No dances available.',
                        style: TextStyle(fontSize: 14, fontFamily: 'Vogun'))
                  else
                    ...show.danceIds.map((danceId) {
                      final dance = allDances.firstWhereOrNull(
                          (d) => d.id.trim() == danceId.trim());
                      if (dance == null) {
                        return const Text('Unknown Dance',
                            style: TextStyle(fontSize: 14, fontFamily: 'Vogun'));
                      }

                      final assignedTeamNames =
                          teamProvider.getTeamNamesForDance(dance.id);

                      return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          color: const Color(0xFFBFCCC2),
                          child: Padding( 
                            padding: const EdgeInsets.all(12),
                            child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                            Text(dance.title,
                                style: const TextStyle(
                                    fontSize: 20, fontFamily: 'Vogun', color: Colors.white)),
                            if (assignedTeamNames.isNotEmpty)
                              Text(
                                '${assignedTeamNames.join(" / ")}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Vogun',
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const Text(
                                'No teams assigned',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Vogun',
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        ),
                      );
                    }),
                ],
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(
                widthFactor: 0.85,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFCCC2),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => setState(() => isExpanded = !isExpanded),
                  child: Text(isExpanded ? 'Close Details' : 'Details'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
