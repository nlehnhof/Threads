import 'package:raw_threads/classes/main_classes/dances.dart';

class DanceStatus {
  final Dances dance;
  String status;

  DanceStatus({required this.dance, this.status = 'Not Ready'});

  factory DanceStatus.fromJson(Map<dynamic, dynamic> json, Dances dance) {
    return DanceStatus(
      dance: dance,
      status: json['status']?.toString() ?? 'Not Ready',
    );
  }

  Map<String, dynamic> toJson() => {
        'danceId': dance.id,
        'status': status,
      };
}
