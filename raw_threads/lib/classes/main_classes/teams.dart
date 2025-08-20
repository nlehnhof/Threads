import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Teams {
  final String id;
  String title;
  final List<String> members;
  final List<String> assigned;

  Teams({
    required this.id,
    required this.title,
    required this.members,
    required this.assigned,
  });

  factory Teams.fromJson(Map<String, dynamic> json) {
    return Teams(
      id: json['id'],
      title: json['title'] ?? 'No Team Assigned',
      members: json['members'],
      assigned: json['assigned'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'members': members,
    'assigned': assigned,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Teams &&
      runtimeType == other.runtimeType &&
      id == other.id;

  @override
  int get hashCode => id.hashCode;
}