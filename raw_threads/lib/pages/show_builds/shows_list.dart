import 'package:flutter/material.dart';
import 'package:raw_threads/classes/main_classes/shows.dart';
import 'package:raw_threads/classes/main_classes/dances.dart';
import 'package:raw_threads/pages/show_builds/shows_item.dart';

class ShowsList extends StatelessWidget {
  final List<Shows> shows;
  final void Function(Shows)? onRemoveShow;
  final void Function(Shows)? onEditShow;
  final List<Dances> allDances;
  final bool isAdmin;

  const ShowsList({
    super.key,
    required this.shows,
    required this.isAdmin,
    this.onRemoveShow,
    this.onEditShow,
    required this.allDances,
  });

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) {
      return const Center(child: Text('No shows available.'));
    }

    return ListView.builder(
      itemCount: shows.length,
      itemBuilder: (ctx, index) {
        final show = shows[index];

        return Dismissible(
          key: ValueKey(show.id),
          onDismissed: (direction) {
            if (onRemoveShow != null) onRemoveShow!(show);
          },
          background: Container(color: Colors.red),
          child: ShowItem(
            show: show,
            onEditShow: onEditShow,
            allDances: allDances,
            isAdmin: isAdmin,
          ),
        );
      },
    );
  }
}
