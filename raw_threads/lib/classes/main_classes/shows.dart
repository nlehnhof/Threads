import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

const uuid = Uuid();

enum Category { ifde, traditionz, tierII, twoPM, tenAM, nineAM, all}

const categoryIcons = {
  Category.ifde: Icons.dangerous,
  Category.traditionz: Icons.holiday_village,
  Category.tierII: Icons.hourglass_bottom_outlined,
  Category.twoPM: Icons.deck,
  Category.tenAM: Icons.lock_clock,
  Category.nineAM: Icons.newspaper,
  Category.all: Icons.disc_full,
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
    required this.adminId,
  });

  final String id;
  final String title;
  final String dates;
  final String location;
  final String dress;
  final String tech;
  final Category category;
  final List<String> danceIds;
  final String adminId; // new field for admin ID

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
      'adminId': adminId, // include admin ID in JSON
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
      adminId: json['adminId'] ?? '', // handle missing admin I
      category: Category.values.firstWhere((e) => e.name == json['category']),
      danceIds: (json['danceIds'] != null)
          ? List<String>.from(json['danceIds'])
          : <String>[],
    );
  }
}
