// import 'package:flutter/material.dart';
// import 'package:threadline_initial/show_dance_classes/dances.dart';

// class SelectedDancesList extends StatelessWidget {
//   final List<Dances> dances;

//   const SelectedDancesList({super.key, required this.dances});

//   @override
//   Widget build(BuildContext context) {
//     if (dances.isEmpty) {
//       return const Text('No dances selected.');
//     }

//     return ListView.separated(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: dances.length,
//       separatorBuilder: (_, __) => const Divider(),
//       itemBuilder: (context, index) {
//         final dance = dances[index];
//         return ListTile(
//           title: Text(dance.title),
//         );
//       },
//     );
//   }
// }