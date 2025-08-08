import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Assignments {
  final String id;
  final String title;
  final String size;
  final String number;
  final String user;

  Assignments({
    required this.id,
    required this.title,
    required this.size,
    required this.number,
    required this.user,
  });

  factory Assignments.fromJson(Map<String, dynamic> json) {
    return Assignments(
      id: json['id'], 
      title: json['title'], 
      size: json['size'], 
      number: json['number'], 
      user: json['user'],
      );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'size': size,
    'number': number,
    'user': user,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Assignments &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}