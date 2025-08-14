import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Issues{
  Issues({
    required this.id,
    required this.title,
    this.image,
  });

  final String id;
  final String title;
  final String? image;

  Map<String, dynamic> toJson() {
    return {
    'id': id,
    'title': title,
    'image': image,
    };
  }  
  
  factory Issues.fromJson(Map<String, dynamic> json) {
    return Issues(
      id: json['id'],
      title: json['title'],
      image: json['image'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Issues &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}