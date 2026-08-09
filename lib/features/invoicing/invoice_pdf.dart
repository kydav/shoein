import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shoein/core/models/client.dart';

/// A single invoice line: e.g. "Sep 4 · Bella · Trim".
typedef InvoiceLine = ({String label, double amount});

/// Builds a simple, professional invoice PDF for [client].
Future<Uint8List> buildInvoicePdf({
  required String businessName,
  required Client client,
  required List<InvoiceLine> lines,
  required double total,
  required String paymentLink,
  required DateTime date,
  required String invoiceNumber,
}) async {
  final doc = pw.Document();
  final money = NumberFormat.currency(symbol: '\$');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              businessName.isEmpty ? 'Invoice' : businessName,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Invoice #$invoiceNumber'),
            pw.Text(DateFormat.yMMMMd().format(date)),
            pw.SizedBox(height: 20),
            pw.Text(
              'Bill to',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(client.name),
            if (client.address.isNotEmpty) pw.Text(client.address),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: const ['Service', 'Amount'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignments: {1: pw.Alignment.centerRight},
              data: [
                for (final l in lines) [l.label, money.format(l.amount)],
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total  ${money.format(total)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (paymentLink.isNotEmpty) ...[
              pw.SizedBox(height: 28),
              pw.Text(
                'Pay online',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.UrlLink(
                destination: _asUrl(paymentLink),
                child: pw.Text(
                  paymentLink,
                  style: const pw.TextStyle(color: PdfColors.blue700),
                ),
              ),
            ],
            pw.Spacer(),
            pw.Text(
              'Thank you!',
              style: const pw.TextStyle(color: PdfColors.grey600),
            ),
          ],
        );
      },
    ),
  );
  return doc.save();
}

String _asUrl(String link) => link.startsWith('http') ? link : 'https://$link';
