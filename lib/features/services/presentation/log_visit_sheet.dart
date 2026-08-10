import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shoein/core/models/horse.dart';
import 'package:shoein/core/models/service_record.dart';
import 'package:shoein/core/providers/auth_provider.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/services/firebase_bootstrap.dart';
import 'package:shoein/core/services/photo_service.dart';
import 'package:shoein/core/theme/app_theme.dart';

const _workTypes = ['Trim', 'Full set', 'Reset', 'Fronts', 'Other'];

/// Opens the "log a visit" sheet. Writes a service record and rolls the horse's
/// last-service date forward (rescheduling next-due).
Future<void> showLogVisitSheet(
  BuildContext context, {
  required String clientId,
  required Horse horse,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LogVisitSheet(clientId: clientId, horse: horse),
  );
}

class _LogVisitSheet extends ConsumerStatefulWidget {
  final String clientId;
  final Horse horse;
  const _LogVisitSheet({required this.clientId, required this.horse});

  @override
  ConsumerState<_LogVisitSheet> createState() => _LogVisitSheetState();
}

class _LogVisitSheetState extends ConsumerState<_LogVisitSheet> {
  DateTime _date = DateTime.now();
  String _workType = _workTypes.first;
  final _notes = TextEditingController();
  final _cost = TextEditingController();
  bool _paid = false;
  bool _busy = false;
  bool _uploading = false;
  final List<String> _photos = [];

  Future<void> _addPhoto(ImageSource source) async {
    final uid = ref.read(authNotifierProvider).uid;
    if (!firebaseReady || uid.isEmpty) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await PhotoService.uploadServicePhoto(
        uid,
        await file.readAsBytes(),
      );
      if (mounted) setState(() => _photos.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(repositoryProvider)
          .logService(
            ServiceRecord(
              id: '',
              clientId: widget.clientId,
              horseId: widget.horse.id,
              date: _date,
              workType: _workType,
              notes: _notes.text.trim(),
              cost: double.tryParse(_cost.text.trim()),
              paid: _paid,
              photoUrls: List.of(_photos),
            ),
          );
      final next = _date.add(Duration(days: widget.horse.intervalWeeks * 7));
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${widget.horse.name} logged — next due ${DateFormat.MMMd().format(next)}',
          ),
        ),
      );
    } catch (e) {
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Log visit — ${widget.horse.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Date', style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(DateFormat.yMMMMd().format(_date)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Work', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final w in _workTypes)
                  ChoiceChip(
                    label: Text(w),
                    selected: _workType == w,
                    onSelected: (_) => setState(() => _workType = w),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cost (optional)',
                prefixText: '\$',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Paid'),
              subtitle: const Text(
                'Paid on the spot — keep off to invoice later',
              ),
              value: _paid,
              onChanged: (v) => setState(() => _paid = v),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'What you did, anything to watch…',
              ),
            ),
            if (firebaseReady) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Photos',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Take photo',
                    onPressed: _uploading
                        ? null
                        : () => _addPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                  IconButton(
                    tooltip: 'Choose photo',
                    onPressed: _uploading
                        ? null
                        : () => _addPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
              if (_uploading) const LinearProgressIndicator(),
              if (_photos.isNotEmpty)
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            _photos[i],
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, size: 20),
                            color: kAnvil,
                            onPressed: () =>
                                setState(() => _photos.removeAt(i)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save visit'),
            ),
          ],
        ),
      ),
    );
  }
}
