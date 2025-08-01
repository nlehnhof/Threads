import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

const uuid = Uuid();

enum Category { IFDE, Traditionz, TierII, TwoPM, TenAM, NineAM, All }

const categoryIcons = {
  Category.IFDE: Icons.dangerous,
  Category.Traditionz: Icons.holiday_village,
  Category.TierII: Icons.hourglass_bottom_outlined,
  Category.TwoPM: Icons.deck,
  Category.TenAM: Icons.lock_clock,
  Category.NineAM: Icons.newspaper,
  Category.All: Icons.disc_full,
};
class Shows {
  Shows({
    required this.id,
    required this.title,
    required this.dates,
    required this.location,
    required this.dress,
    required this.tech,
    required this.category,
    required this.danceIds,
  });

  final String id;
  final String title;
  final String dates;
  final String location;
  final String dress;
  final String tech;
  final Category category;
  final List<String> danceIds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dates': dates,
      'location': location,
      'dress': dress,
      'tech': tech,
      'category': category.name,
      'danceIds': danceIds,
    };
  }

  factory Shows.fromJson(Map<String, dynamic> json) {
    return Shows(
      id: json['id'],
      title: json['title'],
      dates: json['dates'],
      location: json['location'],
      dress: json['dress'],
      tech: json['tech'],
      category: Category.values.firstWhere((e) => e.name == json['category']),
      danceIds: (json['danceIds'] != null)
          ? List<String>.from(json['danceIds'])
          : <String>[],
    );
  }
}
