import 'package:equatable/equatable.dart';

enum XrayType { intraoral, panoramic, cephalometric, other }

class Xray extends Equatable {
  final int? id;
  final int patientId;
  final int? visitId;
  final String filePath;
  final String label;
  final DateTime capturedAt;
  final String? notes;
  final XrayType type;
  final String?
  sourceTag; // Unique identifier for the source image to prevent re-imports

  const Xray({
    this.id,
    required this.patientId,
    this.visitId,
    required this.filePath,
    required this.label,
    required this.capturedAt,
    this.notes,
    this.type = XrayType.intraoral,
    this.sourceTag,
  });

  Xray copyWith({
    int? id,
    int? patientId,
    int? visitId,
    String? filePath,
    String? label,
    DateTime? capturedAt,
    String? notes,
    XrayType? type,
    String? sourceTag,
  }) {
    return Xray(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      visitId: visitId ?? this.visitId,
      filePath: filePath ?? this.filePath,
      label: label ?? this.label,
      capturedAt: capturedAt ?? this.capturedAt,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      sourceTag: sourceTag ?? this.sourceTag,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'visitId': visitId,
      'filePath': filePath,
      'label': label,
      'capturedAt': capturedAt.toIso8601String(),
      'notes': notes,
      'type': type.name,
      'sourceTag': sourceTag,
    };
  }

  factory Xray.fromMap(Map<String, dynamic> map) {
    return Xray(
      id: map['id'] as int?,
      patientId: map['patientId'] as int,
      visitId: map['visitId'] as int?,
      filePath: map['filePath'] as String,
      label: map['label'] as String,
      capturedAt: DateTime.parse(map['capturedAt'] as String),
      notes: map['notes'] as String?,
      type: XrayType.values.byName(map['type'] as String? ?? 'intraoral'),
      sourceTag: map['sourceTag'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    visitId,
    filePath,
    label,
    capturedAt,
    notes,
    type,
    sourceTag,
  ];
}
