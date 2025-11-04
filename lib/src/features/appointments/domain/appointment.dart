class Appointment {
  final int? id;
  final int patientId;
  final DateTime date;
  final String time;

  Appointment({
    this.id,
    required this.patientId,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'date': date.toIso8601String(),
    'time': time,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    patientId: json['patientId'],
    date: DateTime.parse(json['date']),
    time: json['time'],
  );
}
