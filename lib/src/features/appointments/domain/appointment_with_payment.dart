import 'package:dentaltid/src/features/appointments/domain/appointment.dart';

class AppointmentWithPayment {
  final Appointment appointment;
  final double totalCost;
  final double paidAmount;

  AppointmentWithPayment({
    required this.appointment,
    required this.totalCost,
    required this.paidAmount,
  });
}
