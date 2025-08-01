import 'dart:io';

class CostumePiece {
  String title;
  String cleanUp;
  String care;
  String turnIn;
  String available;
  String total;
  File? image; // Nullable because might not always have an image

  CostumePiece({
    required this.title,
    required this.cleanUp,
    required this.care,
    required this.turnIn,
    required this.available,
    required this.total,
    this.image,
  });

  // Convert to Map including image path string (if available)
  Map<String, String> toMap() {
    return {
      'title': title,
      'cleanUp': cleanUp,
      'care': care,
      'turnIn': turnIn,
      'available': available,
      'total': total,
      'imagePath': image?.path ?? '',
    };
  }

  // Create from Map, reconstructing File from path if available
  factory CostumePiece.fromMap(Map<String, dynamic> map) {
    final imagePath = map['imagePath'] as String?;
    return CostumePiece(
      title: map['title'] ?? '',
      cleanUp: map['cleanUp'] ?? '',
      care: map['care'] ?? '',
      turnIn: map['turnIn'] ?? '',
      available: map['available'] ?? '',
      total: map['total'] ?? '',
      image: (imagePath != null && imagePath.isNotEmpty) ? File(imagePath) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CostumePiece &&
          runtimeType == other.runtimeType &&
          title == other.title;

  @override
  int get hashCode => title.hashCode;
}
