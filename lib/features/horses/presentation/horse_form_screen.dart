import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoein/core/models/horse.dart';
import 'package:shoein/core/providers/data_providers.dart';

class HorseFormScreen extends HookConsumerWidget {
  final String clientId;
  final String? horseId;
  const HorseFormScreen({required this.clientId, this.horseId, super.key});

  bool get isEditing => horseId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horses = ref.watch(horsesProvider(clientId)).value ?? const [];
    Horse? existing;
    for (final h in horses) {
      if (h.id == horseId) existing = h;
    }

    final name = useTextEditingController();
    final breed = useTextEditingController();
    final notes = useTextEditingController();
    final serviceDate = useState<DateTime?>(null);
    final intervalWeeks = useState(kDefaultIntervalWeeks);
    final busy = useState(false);
    final loaded = useRef(false);

    if (isEditing && existing != null && !loaded.value) {
      loaded.value = true;
      name.text = existing.name;
      breed.text = existing.breed;
      notes.text = existing.notes;
      serviceDate.value = existing.lastServiceDate;
      intervalWeeks.value = existing.intervalWeeks;
    }

    Future<void> save() async {
      if (name.text.trim().isEmpty) return;
      busy.value = true;
      final messenger = ScaffoldMessenger.of(context);
      try {
        final horse = Horse(
          id: horseId ?? '',
          clientId: clientId,
          name: name.text.trim(),
          breed: breed.text.trim(),
          notes: notes.text.trim(),
          lastServiceDate: serviceDate.value,
          intervalWeeks: intervalWeeks.value,
        );
        await ref.read(repositoryProvider).upsertHorse(horse);
        if (context.mounted) context.pop();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
      } finally {
        busy.value = false;
      }
    }

    Future<void> pickDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: serviceDate.value ?? now,
        firstDate: DateTime(now.year - 5),
        lastDate: now,
      );
      if (picked != null) serviceDate.value = picked;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit horse' : 'New horse'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete horse',
              onPressed: () async {
                await ref
                    .read(repositoryProvider)
                    .deleteHorse(clientId, horseId!);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Field(
            label: 'Name',
            controller: name,
            textCapitalization: TextCapitalization.words,
          ),
          _Field(
            label: 'Breed',
            controller: breed,
            textCapitalization: TextCapitalization.words,
          ),
          Text('Trim cycle', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text('Every'),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: intervalWeeks.value > 1
                    ? () => intervalWeeks.value--
                    : null,
              ),
              SizedBox(
                width: 84,
                child: Text(
                  '${intervalWeeks.value} ${intervalWeeks.value == 1 ? 'week' : 'weeks'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: intervalWeeks.value < 26
                    ? () => intervalWeeks.value++
                    : null,
              ),
            ],
          ),
          if (serviceDate.value != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Next due ${DateFormat.yMMMMd().format(serviceDate.value!.add(Duration(days: intervalWeeks.value * 7)))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 14),
          Text(
            'Last service date',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: pickDate,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                serviceDate.value == null
                    ? 'Not set'
                    : DateFormat.yMMMMd().format(serviceDate.value!),
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft,
            ),
          ),
          if (serviceDate.value != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => serviceDate.value = null,
                child: const Text('Clear'),
              ),
            ),
          const SizedBox(height: 14),
          _Field(
            label: 'Notes',
            controller: notes,
            hint: 'Shoeing details, temperament…',
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: busy.value ? null : save,
            child: busy.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEditing ? 'Save changes' : 'Add horse'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final TextCapitalization textCapitalization;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
