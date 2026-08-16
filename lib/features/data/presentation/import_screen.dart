import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/services/import_service.dart';
import 'package:shoein/core/theme/app_theme.dart';

/// Import clients from a CSV (the template farmers fill in a spreadsheet).
/// Flow: download template → pick file → preview (with dedupe) → import.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportPlan? _plan;
  bool _importing = false;
  int _done = 0;
  bool _finished = false;
  int _imported = 0;
  String? _error;

  Future<void> _downloadTemplate() async {
    final file = await buildClientImportTemplate();
    await SharePlus.instance.share(
      ShareParams(files: [file], subject: 'Shoein client import template'),
    );
  }

  Future<void> _pickFile() async {
    setState(() => _error = null);
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (files.isEmpty) return;
    final content = utf8.decode(
      await files.first.readAsBytes(),
      allowMalformed: true,
    );
    final existing = await ref.read(repositoryProvider).watchClients().first;
    final plan = planClientImport(content, existing);
    if (!mounted) return;
    if (!plan.headerOk) {
      setState(
        () => _error =
            'That file needs a header row with a "name" column. Download the '
            'template above, fill it in, and import that.',
      );
      return;
    }
    setState(() => _plan = plan);
  }

  Future<void> _runImport() async {
    final plan = _plan;
    if (plan == null || plan.toImport.isEmpty) return;
    if (ref.read(isReadOnlyProvider)) {
      context.push('/paywall');
      return;
    }
    setState(() {
      _importing = true;
      _done = 0;
      _error = null;
    });
    try {
      await runClientImport(
        ref.read(repositoryProvider),
        plan.toImport,
        onProgress: (d, t) {
          if (mounted) setState(() => _done = d);
        },
      );
      if (!mounted) return;
      setState(() {
        _importing = false;
        _finished = true;
        _imported = plan.toImport.length;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _error =
            'Import failed partway through. Some clients may have been '
            'added — check your list.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import clients')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (_finished)
            _finishedView(context)
          else if (_importing)
            _progress(context)
          else if (_plan != null)
            _preview(context, _plan!)
          else
            _start(context),
        ],
      ),
    );
  }

  Widget _start(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bring your clients over',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Already have your clients in a spreadsheet? Download the '
                'template, fill in one client per row (name, phone, email, '
                'address, notes), then import it here. We skip anyone already '
                'in your book, and put addresses on the map.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _downloadTemplate,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Download CSV template'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Choose a CSV file'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: kOverdueRed),
          ),
        ],
      ],
    );
  }

  Widget _preview(BuildContext context, ImportPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.toImport.isEmpty
                    ? 'Nothing new to import'
                    : '${plan.toImport.length} new '
                          '${plan.toImport.length == 1 ? 'client' : 'clients'} '
                          'to import',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (plan.duplicates > 0 || plan.invalid > 0) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    if (plan.duplicates > 0)
                      '${plan.duplicates} already in your book',
                    if (plan.invalid > 0) '${plan.invalid} with no name',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (plan.toImport.isNotEmpty) ...[
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              children: [
                for (final c in plan.toImport)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: kForge,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        if (c.address.isNotEmpty)
                          Icon(
                            Icons.place_outlined,
                            size: 16,
                            color: context.colors.textSecondary,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _runImport,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: Text(
              'Import ${plan.toImport.length} '
              '${plan.toImport.length == 1 ? 'client' : 'clients'}',
            ),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() {
            _plan = null;
            _error = null;
          }),
          child: const Text('Choose a different file'),
        ),
      ],
    );
  }

  Widget _progress(BuildContext context) {
    final total = _plan?.toImport.length ?? 0;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Importing…', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: total == 0 ? null : _done / total),
          const SizedBox(height: 10),
          Text(
            '$_done of $total',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _finishedView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, color: kForge, size: 40),
              const SizedBox(height: 10),
              Text(
                'Imported $_imported '
                '${_imported == 1 ? 'client' : 'clients'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'They\'re in your book now.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.pop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
