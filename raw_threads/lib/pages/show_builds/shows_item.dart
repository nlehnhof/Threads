import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/dances.dart' as mydances;
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/pages/show_builds/edit_show_page.dart';
import 'package:collection/collection.dart';
// import 'package:threadline_initial/logins/users.dart';

class ShowItem extends StatefulWidget {
  final Shows show;
  final void Function(Shows show)? onEditShow; // now optional
  final List<mydances.Dances> allDances;
  final bool isAdmin; // new flag

  const ShowItem({
    required this.show,
    required this.allDances,
    this.onEditShow,
    this.isAdmin = false, // default false = regular user
    super.key,
  });

  @override
  State<ShowItem> createState() => _ShowItemState();
}

class _ShowItemState extends State<ShowItem> {
  late Shows _show;
  bool isExpanded = false;
  List<mydances.Dances> loadedDances = [];

  @override
  void initState() {
    super.initState();
    _show = widget.show;
  }

  @override
  Widget build(BuildContext context) {
    final allDances = widget.allDances;
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
                  _show.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    fontFamily: 'Vogun',
                  ),
                ),
                if (widget.isAdmin) // Only show Edit if admin
                  GestureDetector(
                    onTap: () async {
                      final updatedShow = await Navigator.of(context).push<Shows>(
                        MaterialPageRoute(
                          builder: (ctx) => EditShowPage(
                            show: _show,
                            onSave: (updated) {},
                          ),
                        ),
                      );
                      if (updatedShow != null) {
                        setState(() => _show = updatedShow);
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
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                children: [
                  const TextSpan(
                    text: 'Location: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vogun'),
                  ),
                  TextSpan(
                    text: _show.location,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                children: [
                  const TextSpan(
                    text: 'Performances: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vogun'),
                  ),
                  TextSpan(
                    text: _show.dates,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                children: [
                  const TextSpan(
                    text: 'Tech: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vogun'),
                  ),
                  TextSpan(
                    text: _show.tech,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14),
                children: [
                  const TextSpan(
                    text: 'Dress: ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vogun'),
                  ),
                  TextSpan(
                    text: _show.dress,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              firstChild: const SizedBox(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dances:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Vogun')),
                  if (_show.danceIds.isEmpty)
                    const Text('No dances assigned.', style: TextStyle(fontSize: 14, fontFamily: 'Vogun'),
                  )
                  else if (allDances.isEmpty)
                    const Text('No dances available.', style: TextStyle(fontSize: 14, fontFamily: 'Vogun'),
                  )
                  else ..._show.danceIds.map((danceId) {
                    final match = allDances.firstWhereOrNull((dance) => dance.id.trim() == danceId.trim());
                    return Text(match?.title ?? 'Unknown Dance', style: const TextStyle(fontSize: 14, fontFamily: 'Vogun'));
                    }),
                ],
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
