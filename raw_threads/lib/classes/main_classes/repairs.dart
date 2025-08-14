import 'package:uuid/uuid.dart';
import 'package:raw_threads/classes/main_classes/issues.dart';

const uuid = Uuid();

class Repairs {
  Repairs({
    required this.id,
    required this.danceId,
    required this.gender,
    required this.costumeTitle,
    required this.team,
    required this.costumeId,
    required this.name,
    required this.email,
    required this.number,
    this.issues = const [],
    this.completed = false,
    this.photoPath,
    this.comments,
  });

  final String id;
  final String danceId;
  final String gender;
  final String team;
  final String costumeId;
  final String costumeTitle;
  final String name;
  final String email;
  final String number;
  List<Issues> issues;
  bool completed;
  String? photoPath;
  String? comments;

  Repairs copyWith({
    String? id,
    String? danceId,
    String? gender,
    String? team,
    String? costumeTitle,
    String? costumeId,
    String? name,
    String? email,
    String? number,
    List<Issues>? issues,
    bool? completed,
  }) {
    return Repairs(
      id: id ?? this.id,
      danceId: danceId ?? this.danceId,
      gender: gender ?? this.gender,
      team: team ?? this.team,
      costumeTitle: costumeTitle ?? this.costumeTitle,
      costumeId: costumeId ?? this.costumeId,
      name: name ?? this.name,
      email: email ?? this.email,
      number: number ?? this.number,
      issues: issues ?? this.issues,
      completed: completed ?? this.completed,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'danceId': danceId,
      'gender': gender,
      'costumeTitle': costumeTitle,
      'costumeId': costumeId,
      'team': team,
      'name': name,
      'email': email,
      'number': number,
      'issues': issues.map((i) => i.toJson()).toList(),
      'completed': completed, // save as boolean
      'photoPath': photoPath ?? '',
      'comments': comments ?? '',
    };
  }

  factory Repairs.fromJson(Map<String, dynamic> json) {
    return Repairs(
      id: json['id'] ?? uuid.v4(),
      danceId: json['danceId'] ?? '',
      gender: json['gender'] ?? '',
      costumeId: json['costumeId'] ?? '',
      costumeTitle: json['costumeTitle'] ?? '',
      team: json['team'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      number: json['number'] ?? '',
      issues: (json['issues'] as List?)
              ?.map((i) => Issues.fromJson(i))
              .toList() ??
          [],
      completed: json['completed'] == true || json['completed'] == 'true',
      photoPath: json['photoPath'] as String?,
      comments: json['comments'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Repairs && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
