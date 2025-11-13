import 'package:dentaltid/src/core/database_service.dart';
import 'package:dentaltid/src/core/exceptions.dart';
import 'package:dentaltid/src/features/sessions/data/session_repository.dart';
import 'package:dentaltid/src/features/sessions/domain/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:dentaltid/src/features/security/domain/audit_event.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(DatabaseService.instance);
});

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(
    ref.watch(sessionRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final sessionsProvider = FutureProvider<List<Session>>((ref) async {
  final service = ref.watch(sessionServiceProvider);
  return service.getSessions();
});

final upcomingSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final service = ref.watch(sessionServiceProvider);
  return service.getUpcomingSessions();
});

final todaysSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final service = ref.watch(sessionServiceProvider);
  return service.getTodaysSessions();
});

class SessionService {
  final SessionRepository _repository;
  final AuditService _auditService;

  SessionService(this._repository, this._auditService);

  Future<int> addSession(Session session) async {
    try {
      final sessionId = await _repository.createSession(session);
      _auditService.logEvent(
        AuditAction.createSession,
        details:
            'Session ${session.sessionNumber} for visit ${session.visitId} on ${session.dateTime} created.',
      );
      return sessionId;
    } catch (e) {
      ErrorHandler.logError(e);
      rethrow;
    }
  }

  Future<List<Session>> getSessions() async {
    return await _repository.getSessions();
  }

  Future<List<Session>> getSessionsByVisitId(int visitId) async {
    return await _repository.getSessionsByVisitId(visitId);
  }

  Future<Session?> getSessionById(int id) async {
    return await _repository.getSessionById(id);
  }

  Future<void> updateSession(Session session) async {
    await _repository.updateSession(session);
    _auditService.logEvent(
      AuditAction.updateSession,
      details:
          'Session ${session.sessionNumber} for visit ${session.visitId} updated.',
    );
  }

  Future<void> deleteSession(int id) async {
    await _repository.deleteSession(id);
    _auditService.logEvent(
      AuditAction.deleteSession,
      details: 'Session with ID $id deleted.',
    );
  }

  Future<List<Session>> getUpcomingSessions() async {
    return await _repository.getUpcomingSessions();
  }

  Future<List<Session>> getTodaysSessions() async {
    return await _repository.getTodaysSessions();
  }

  Future<double> getTotalAmountForVisit(int visitId) async {
    return await _repository.getTotalAmountForVisit(visitId);
  }

  Future<double> getPaidAmountForVisit(int visitId) async {
    return await _repository.getPaidAmountForVisit(visitId);
  }

  Future<int> getNextSessionNumber(int visitId) async {
    final sessions = await _repository.getSessionsByVisitId(visitId);
    if (sessions.isEmpty) return 1;
    return sessions
            .map((s) => s.sessionNumber)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }
}
