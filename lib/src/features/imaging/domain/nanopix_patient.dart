import 'package:equatable/equatable.dart';

class NanoPixPatient extends Equatable {
  final int id; // The primary key (pk)
  final String patientId; // The string identifier (id)
  final String? firstName;
  final String? lastName;
  final String? birthDate; // Stored as string, e.g. 'YYYY-MM-DD'
  final String? gender; // Stored as string 'Male'/'Female'
  final String? folderName; // The name of the directory holding the images
  final DateTime? createdAt;

  const NanoPixPatient({
    required this.id,
    required this.patientId,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.gender,
    this.folderName,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        patientId,
        firstName,
        lastName,
        birthDate,
        gender,
        folderName,
        createdAt,
      ];

  factory NanoPixPatient.fromMap(Map<String, dynamic> map) {
    // Column names observed in NanoPix.db3: pk, id, first_name, last_name, birthdate, sex, created_datetime
    final patientId = map['id'] as String;
    DateTime? created;
    if (map['created_datetime'] != null) {
      try {
        created = DateTime.parse(map['created_datetime'] as String);
      } catch (_) {}
    }
    return NanoPixPatient(
      id: map['pk'] as int,
      patientId: patientId,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      birthDate: map['birthdate'] as String?,
      gender: map['sex'] as String?,
      // In the folder structure, folders are named after the patient 'id'
      folderName: patientId,
      createdAt: created,
    );
  }

  String get fullName => '$lastName, $firstName';
}
