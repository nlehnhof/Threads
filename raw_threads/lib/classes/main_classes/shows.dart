import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

const uuid = Uuid();

class Shows {
  Shows({
    required this.id,
    required this.title,
    required this.dates,
    required this.location,
    required this.dress,
    required this.tech,
    required this.danceIds,
    required this.adminId,
  });

  final String id;
  final String title;
  final String dates;
  final String location;
  final String dress;
  final String tech;
  final List<String> danceIds;
  final String adminId;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dates': dates,
      'location': location,
      'dress': dress,
      'tech': tech,
      'danceIds': danceIds,
      'adminId': adminId,
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
      adminId: json['adminId'] ?? '',
      danceIds: (json['danceIds'] != null)
          ? List<String>.from(json['danceIds'])
          : <String>[],
    );
  }

  // ✅ helper for immutability
  Shows copyWith({
    String? title,
    String? dates,
    String? location,
    String? dress,
    String? tech,
    List<String>? danceIds,
  }) {
    return Shows(
      id: id,
      title: title ?? this.title,
      dates: dates ?? this.dates,
      location: location ?? this.location,
      dress: dress ?? this.dress,
      tech: tech ?? this.tech,
      danceIds: danceIds ?? this.danceIds,
      adminId: adminId,
    );
  }
}
