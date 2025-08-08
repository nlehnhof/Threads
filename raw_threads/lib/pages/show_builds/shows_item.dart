import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/pages/show_builds/edit_show_page.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:raw_threads/providers/dance_inventory_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final show = widget.show;
    final allDances = context.watch<DanceInventoryProvider>().dances;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF9F9F9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  show.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    fontFamily: 'Vogun',
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
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow('Location', show.location),
            _infoRow('Performances', show.dates),
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
                          fontSize: 14,
                          fontFamily: 'Vogun')),
                  if (show.danceIds.isEmpty)
                    const Text('No dances assigned.',
                        style:
                            TextStyle(fontSize: 14, fontFamily: 'Vogun'))
                  else if (allDances.isEmpty)
                    const Text('No dances available.',
                        style:
                            TextStyle(fontSize: 14, fontFamily: 'Vogun'))
                  else
                    ...show.danceIds.map((danceId) {
                      final match = allDances.firstWhereOrNull(
                          (dance) => dance.id.trim() == danceId.trim(),
                      );
                      return Text(match?.title ?? 'Unknown Dance',
                          style: const TextStyle(
                              fontSize: 14, fontFamily: 'Vogun'));
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
                widthFactor: 0.7,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFCFC6),
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  Widget _infoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vogun'),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
