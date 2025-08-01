import 'package:raw_threads/classes/main_classes/dances.dart' as mydance;

class DanceWithStatus {
  final mydance.Dances dance;
  String status;

  DanceWithStatus({required this.dance, this.status = 'Not Ready'});

  Map<String, dynamic> toJson() => {
    'dance': dance.toJson(),
    'status': status,
  };

  factory DanceWithStatus.fromJson(Map<String, dynamic> json) {
    return DanceWithStatus(
      dance: mydance.Dances.fromJson(json['dance']),
      status: json['status'],
    );
  }
}