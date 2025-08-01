import 'package:uuid/uuid.dart';
import 'package:raw_threads/classes/main_classes/costume_piece.dart'; // Ensure this exists

const uuid = Uuid();

enum Category { distributed, notready, prepped }

class Dances {
  Dances({
    required this.id,
    required this.title,
    required this.country,
    this.available = 0,
    this.total = 0,
    this.category = Category.notready,
    this.leftImagePath,
    this.rightImagePath,
    this.costumesMen = const [],
    this.costumesWomen = const [],
    this.ownerUsername, // new optional field for ownership
  });

  final String id;
  final String title;
  final String country;
  final int available;
  final int total;
  final Category category;
  final String? leftImagePath;
  final String? rightImagePath;
  List<CostumePiece> costumesMen;
  List<CostumePiece> costumesWomen;
  final String? ownerUsername; // added ownerUsername

  // Convert to Map including costumes and ownerUsername
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'country': country,
      'available': available,
      'total': total,
      'category': category.name,
      'leftImagePath': leftImagePath,
      'rightImagePath': rightImagePath,
      'costumesMen': costumesMen.map((c) => c.toMap()).toList(),
      'costumesWomen': costumesWomen.map((c) => c.toMap()).toList(),
      'ownerUsername': ownerUsername,
    };
  }

  // Create from Map including costumes and ownerUsername
  factory Dances.fromJson(Map<String, dynamic> json) {
    return Dances(
      id: json['id'],
      title: json['title'],
      country: json['country'],
      available: json['available'] ?? 0,
      total: json['total'] ?? 0,
      category: Category.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => Category.notready,
      ),
      leftImagePath: json['leftImagePath'],
      rightImagePath: json['rightImagePath'],
      costumesMen: (json['costumesMen'] as List?)
              ?.map((c) => CostumePiece.fromMap(c))
              .toList() ??
          [],
      costumesWomen: (json['costumesWomen'] as List?)
              ?.map((c) => CostumePiece.fromMap(c))
              .toList() ??
          [],
      ownerUsername: json['ownerUsername'], // read ownerUsername from json
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dances &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
