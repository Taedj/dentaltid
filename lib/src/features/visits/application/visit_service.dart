import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dentaltid/src/features/visits/data/visit_repository.dart';
import 'package:dentaltid/src/features/visits/domain/visit.dart';
import 'package:dentaltid/src/core/database_service.dart';

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository(DatabaseService.instance);
});

final visitServiceProvider = Provider<VisitService>((ref) {
  return VisitService(ref.watch(visitRepositoryProvider));
});

class VisitService {
  final VisitRepository _visitRepository;

  VisitService(this._visitRepository);

  Future<int> addVisit(Visit visit) async {
    return await _visitRepository.addVisit(visit);
  }

  Future<Visit?> getVisitById(int id) async {
    return await _visitRepository.getVisitById(id);
  }

  Future<List<Visit>> getVisitsByPatientId(int patientId) async {
    return await _visitRepository.getVisitsByPatientId(patientId);
  }

  Future<int> updateVisit(Visit visit) async {
    return await _visitRepository.updateVisit(visit);
  }

  Future<int> deleteVisit(int id) async {
    return await _visitRepository.deleteVisit(id);
  }
}

final visitsByPatientProvider =
    FutureProvider.family<List<Visit>, int>(((ref, patientId) async {
  final service = ref.watch(visitServiceProvider);
  return service.getVisitsByPatientId(patientId);
}));
