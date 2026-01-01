import 'dart:io';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrescriptionPdfHelper {
  static Future<void> generateAndPrint({
    required Prescription prescription,
    required UserProfile userProfile,
    required String language,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final logoImage = prescription.logoPath != null &&
            File(prescription.logoPath!).existsSync()
        ? pw.MemoryImage(File(prescription.logoPath!).readAsBytesSync())
        : null;

    final bgImage = prescription.backgroundImagePath != null &&
            File(prescription.backgroundImagePath!).existsSync()
        ? pw.MemoryImage(File(prescription.backgroundImagePath!).readAsBytesSync())
        : null;

    final t = {
      'fr': {
        'dr': 'Dr.',
        'surgeon': 'Chirurgien Dentiste',
        'city': 'Ville',
        'on': 'le',
        'order_no': 'N° d\'ordre',
        'patient': 'PATIENT',
        'age': 'Age',
        'years': 'Ans',
        'prescription_title': 'ORDONNANCE',
        'notes': 'NOTES',
        'advice': 'CONSEILS',
        'signature': 'Signature & Cachet',
        'tel': 'Tél',
      },
      'en': {
        'dr': 'Dr.',
        'surgeon': 'Dental Surgeon',
        'city': 'City',
        'on': 'on',
        'order_no': 'Order No.',
        'patient': 'PATIENT',
        'age': 'Age',
        'years': 'Yrs',
        'prescription_title': 'PRESCRIPTION',
        'notes': 'NOTES',
        'advice': 'ADVICE',
        'signature': 'Signature & Stamp',
        'tel': 'Tel',
      },
      'ar': {
        'dr': 'د.',
        'surgeon': 'جراح أسنان',
        'city': 'المدينة',
        'on': 'في',
        'order_no': 'رقم الترتيب',
        'patient': 'المريض',
        'age': 'العمر',
        'years': 'سنة',
        'prescription_title': 'وصفة طبية',
        'notes': 'ملاحظات',
        'advice': 'نصائح',
        'signature': 'التوقيع والختم',
        'tel': 'هاتف',
      },
    }[language] ??
    {
        'dr': 'Dr.',
        'surgeon': 'Chirurgien Dentiste',
        'city': 'Ville',
        'on': 'le',
        'order_no': 'N° d\'ordre',
        'patient': 'PATIENT',
        'age': 'Age',
        'years': 'Ans',
        'prescription_title': 'ORDONNANCE',
        'notes': 'NOTES',
        'advice': 'CONSEILS',
        'signature': 'Signature & Cachet',
        'tel': 'Tél',
      };

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                // Background
                if (bgImage != null)
                  pw.Opacity(
                    opacity: prescription.backgroundOpacity,
                    child: pw.Center(
                      child: pw.Image(bgImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                // Content
                pw.Padding(
                  padding: const pw.EdgeInsets.all(24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                if (prescription.showLogo && logoImage != null)
                                  pw.Container(
                                    height: 50,
                                    child: pw.Image(
                                      logoImage,
                                      alignment: pw.Alignment.centerLeft,
                                    ),
                                  ),
                                pw.Text(
                                  (userProfile.clinicName ??
                                          'Cabinet Dentaire')
                                      .toUpperCase(),
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  userProfile.dentistName ??
                                      '${t['dr']} Dentist',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  t['surgeon']!,
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                if (prescription.showQrCode &&
                                    prescription.qrContent != null)
                                  pw.Container(
                                    width: 40,
                                    height: 40,
                                    child: pw.BarcodeWidget(
                                      barcode: pw.Barcode.qrCode(),
                                      data: prescription.qrContent!,
                                    ),
                                  ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  '${t['order_no']}: ${prescription.orderNumber}',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                if (userProfile.phoneNumber != null)
                                  pw.Text(
                                    '${t['tel']}: ${userProfile.phoneNumber}',
                                    style: const pw.TextStyle(fontSize: 8),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Divider(thickness: 0.5),
                      pw.SizedBox(height: 5),
                      // Patient Info
                      pw.Row(
                        children: [
                          pw.Text(
                            '${t['patient']}: ',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '${prescription.patientName} ${prescription.patientFamilyName}'
                                .toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Spacer(),
                          pw.Text(
                            '${t['age']}: ${prescription.patientAge} ${t['years']}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      // Date
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          '${userProfile.province ?? ''} ${t['on']} : ${DateFormat('dd / MM / yyyy').format(prescription.date)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      // Title
                      pw.Center(
                        child: pw.Text(
                          t['prescription_title']!,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      // Medicines
                      pw.Expanded(
                        child: pw.ListView.builder(
                          itemCount: prescription.medicines.length,
                          itemBuilder: (pw.Context context, int index) {
                            final m = prescription.medicines[index];
                            String route = m.route;
                            if (language == 'fr' &&
                                route.toLowerCase() == 'orally') {
                              route = 'voie orale';
                            }
                            final posology = 
                                '${m.quantity} ${m.frequency} par $route pendant ${m.time}';

                            return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 10),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    children: [
                                      pw.Text(
                                        '• ',
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                      pw.Text(
                                        m.medicineName.toUpperCase(),
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.only(
                                      left: 12,
                                      top: 2,
                                    ),
                                    child: pw.Text(
                                      posology,
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontStyle: pw.FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Notes / Advice
                      if (prescription.showNotes && prescription.notes != null) ...[
                        pw.Text(
                          '${t['notes']}:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red,
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Text(
                            prescription.notes!,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                      ],
                      if (prescription.showAdvice && prescription.advice != null) ...[
                        pw.Text(
                          '${t['advice']}:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          prescription.advice!,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                      ],
                      pw.SizedBox(height: 20),
                      // Footer
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            userProfile.clinicAddress ?? '',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                          pw.Column(
                            children: [
                              pw.Text(
                                t['signature']!,
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                              pw.SizedBox(height: 30),
                              pw.Container(
                                width: 100,
                                height: 0.5,
                                color: PdfColors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Prescription_${prescription.patientName}',
    );
  }
}
