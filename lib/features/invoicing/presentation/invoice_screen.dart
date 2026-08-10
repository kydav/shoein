import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/providers/settings_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';
import 'package:shoein/features/invoicing/invoice_pdf.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceScreen extends HookConsumerWidget {
  final String clientId;
  const InvoiceScreen({required this.clientId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider(clientId)).valueOrNull;
    final billables = ref.watch(clientUnpaidServicesProvider(clientId));
    final businessName = ref.watch(businessNameProvider);
    final paymentLink = ref.watch(paymentLinkProvider);
    final excluded = useState(<String>{});
    final busy = useState(false);
    final invoiceNo = useMemoized(
      () => DateFormat('yyMMdd-HHmm').format(DateTime.now()),
    );
    final money = NumberFormat.currency(symbol: '\$');

    if (client == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final included = billables
        .where((b) => !excluded.value.contains(b.service.id))
        .toList();
    final total = included.fold<double>(
      0,
      (sum, b) => sum + (b.service.cost ?? 0),
    );

    Future<Uint8List> buildPdf() => buildInvoicePdf(
      businessName: businessName,
      client: client,
      lines: [
        for (final b in included)
          (
            label:
                '${DateFormat.MMMd().format(b.service.date)}  ·  ${b.horseName}'
                '${b.service.workType.isEmpty ? '' : '  ·  ${b.service.workType}'}',
            amount: b.service.cost ?? 0,
          ),
      ],
      total: total,
      paymentLink: paymentLink,
      date: DateTime.now(),
      invoiceNumber: invoiceNo,
    );

    // Render the PDF in-app with the printing package's Pdfium-backed preview
    // instead of handing it to iOS's print controller (which crashes rendering
    // some documents). The user can still print/share from the preview's own
    // toolbar.
    Future<void> preview() async {
      final navigator = Navigator.of(context);
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Invoice — ${client.name}')),
            body: PdfPreview(
              build: (_) => buildPdf(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              // Keep the OS print controller (which was crashing) out of the
              // path — render in-app and let the user share the PDF instead.
              allowPrinting: false,
              allowSharing: true,
              pdfFileName: 'invoice_$invoiceNo.pdf',
            ),
          ),
        ),
      );
    }

    Future<void> emailInvoice() async {
      busy.value = true;
      try {
        final bytes = await buildPdf();
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/invoice_$invoiceNo.pdf');
        await file.writeAsBytes(bytes);
        await FlutterEmailSender.send(
          Email(
            subject:
                '${businessName.isEmpty ? 'Invoice' : businessName} — ${money.format(total)}',
            body:
                'Hi ${client.name},\n\nHere is your invoice for ${money.format(total)}.'
                '${paymentLink.isEmpty ? '' : '\n\nPay here: $paymentLink'}'
                '\n\nThank you!${businessName.isEmpty ? '' : '\n$businessName'}',
            recipients: [if (client.email.isNotEmpty) client.email],
            attachmentPaths: [file.path],
          ),
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open email: $e')));
        }
      } finally {
        busy.value = false;
      }
    }

    Future<void> textInvoice() async {
      final body = Uri.encodeComponent(
        '${businessName.isEmpty ? 'Invoice' : businessName}: ${money.format(total)} for '
        '${included.length} ${included.length == 1 ? 'visit' : 'visits'}.'
        '${paymentLink.isEmpty ? '' : ' Pay: $paymentLink'}',
      );
      final uri = Uri.parse('sms:${client.phone}?body=$body');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }

    Future<void> markPaid() async {
      final repo = ref.read(repositoryProvider);
      for (final b in included) {
        await repo.setServicePaid(
          clientId,
          b.service.horseId,
          b.service.id,
          true,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${included.length} ${included.length == 1 ? 'visit' : 'visits'} marked paid',
            ),
          ),
        );
        Navigator.of(context).maybePop();
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Invoice — ${client.name}')),
      body: billables.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No unpaid visits to invoice.\nLog a visit with a cost first.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    children: [
                      for (final b in billables)
                        CheckboxListTile(
                          value: !excluded.value.contains(b.service.id),
                          onChanged: (v) {
                            final next = {...excluded.value};
                            if (v == true) {
                              next.remove(b.service.id);
                            } else {
                              next.add(b.service.id);
                            }
                            excluded.value = next;
                          },
                          title: Text(
                            '${b.horseName}'
                            '${b.service.workType.isEmpty ? '' : ' · ${b.service.workType}'}',
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd().format(b.service.date),
                          ),
                          secondary: Text(
                            money.format(b.service.cost ?? 0),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              money.format(total),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: kForge),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: included.isEmpty ? null : preview,
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Preview'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: included.isEmpty
                                    ? null
                                    : textInvoice,
                                icon: const Icon(Icons.sms_outlined),
                                label: const Text('Text'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: (busy.value || included.isEmpty)
                              ? null
                              : emailInvoice,
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email invoice (PDF)'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                        TextButton(
                          onPressed: included.isEmpty ? null : markPaid,
                          child: Text('Mark ${included.length} paid'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
