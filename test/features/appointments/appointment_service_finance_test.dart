import 'package:dentaltid/src/features/appointments/application/appointment_service.dart';
import 'package:dentaltid/src/features/appointments/data/appointment_repository.dart';
import 'package:dentaltid/src/features/appointments/domain/appointment.dart';
import 'package:dentaltid/src/features/finance/application/finance_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dentaltid/src/features/security/application/audit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'appointment_service_finance_test.mocks.dart';

@GenerateMocks([AppointmentRepository, AuditService, FinanceService])
void main() {
  group('AppointmentService Finance Integration', () {
    late MockAppointmentRepository mockAppointmentRepository;
    late MockAuditService mockAuditService;
    late MockFinanceService mockFinanceService;
    late AppointmentService appointmentService;
    late ProviderContainer container;

    setUp(() {
      mockAppointmentRepository = MockAppointmentRepository();
      mockAuditService = MockAuditService();
      mockFinanceService = MockFinanceService();

      container = ProviderContainer(
        overrides: [
          appointmentRepositoryProvider.overrideWithValue(
            mockAppointmentRepository,
          ),
          auditServiceProvider.overrideWithValue(mockAuditService),
          financeServiceProvider.overrideWithValue(mockFinanceService),
        ],
      );

      appointmentService = container.read(appointmentServiceProvider);
    });

    tearDown(() {
      container.dispose();
      reset(mockAppointmentRepository);
      reset(mockAuditService);
      reset(mockFinanceService);
    });

    final testAppointment = Appointment(
      id: 1,
      patientId: 101,
      dateTime: DateTime(2023, 1, 1, 10, 0),
      appointmentType: 'Consultation',
    );

    test(
      'addAppointment does not create finance transaction directly, but logs audit event',
      () async {
        when(
          mockAppointmentRepository.getAppointmentByPatientAndDateTime(
            any,
            any,
          ),
        ).thenAnswer((_) async => null);
        when(
          mockAppointmentRepository.createAppointment(any),
        ).thenAnswer((_) async => testAppointment);
        when(
          mockAuditService.logEvent(any, details: anyNamed('details')),
        ).thenAnswer((_) async => Future.value());

        await appointmentService.addAppointment(testAppointment);

        verify(
          mockAppointmentRepository.createAppointment(testAppointment),
        ).called(1);
        verify(
          mockAuditService.logEvent(
            any,
            details:
                'Appointment for patient 101 on 2023-01-01 10:00:00.000 created.',
          ),
        ).called(1);
        verifyZeroInteractions(mockFinanceService); // Finance is handled in UI
      },
    );

    test(
      'updateAppointment does not create finance transaction directly, but logs audit event',
      () async {
        when(
          mockAppointmentRepository.updateAppointment(any),
        ).thenAnswer((_) async => Future.value());
        when(
          mockAuditService.logEvent(any, details: anyNamed('details')),
        ).thenAnswer((_) async => Future.value());

        await appointmentService.updateAppointment(testAppointment);

        verify(
          mockAppointmentRepository.updateAppointment(testAppointment),
        ).called(1);
        verify(
          mockAuditService.logEvent(
            any,
            details:
                'Appointment for patient 101 on 2023-01-01 10:00:00.000 updated.',
          ),
        ).called(1);
        verifyZeroInteractions(mockFinanceService); // Finance is handled in UI
      },
    );
  });
}
