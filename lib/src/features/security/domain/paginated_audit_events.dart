import 'package:dentaltid/src/features/security/domain/audit_event.dart';

class PaginatedAuditEvents {
  final List<AuditEvent> events;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  PaginatedAuditEvents({
    required this.events,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });
}
