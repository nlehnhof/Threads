import 'package:uuid/uuid.dart';

const uuid = Uuid();

class CostumePiece {
  final String id;
  final String title;
  final String care;
  final String turnIn;
  final int available;
  final int total;
  final String? imagePath; // Local file path to image

  CostumePiece({
    required this.id,
    required this.title,
    required this.care,
    required this.turnIn,
    required this.available,
    required this.total,
    this.imagePath,
  });

  factory CostumePiece.fromJson(Map<String, dynamic> json) {
    return CostumePiece(
      id: json['id'],
      title: json['title'],
      care: json['care'] as String? ?? '',
      turnIn: json['turnIn'] as String? ?? '',
      available: json['available'] is int ? json['available'] : int.tryParse(json['available'] ?? ''),
      total: json['total'] is int ? json['total'] : int.tryParse(json['total'] ?? ''),
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'care': care,
        'turnIn': turnIn,
        'available': available,
        'total': total,
        'imagePath': imagePath,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CostumePiece &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
