import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoein/core/models/appointment.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/providers/data_providers.dart';

class AppointmentFormScreen extends HookConsumerWidget {
  final String? appointmentId;
  final DateTime? initialDay;
  const AppointmentFormScreen({this.appointmentId, this.initialDay, super.key});

  bool get isEditing => appointmentId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider).valueOrNull ?? const [];
    final appts = ref.watch(appointmentsProvider).valueOrNull ?? const [];
    Appointment? existing;
    for (final a in appts) {
      if (a.id == appointmentId) existing = a;
    }

    final clientId = useState<String?>(null);
    final start = useState<DateTime>(
      initialDay == null
          ? DateTime.now().copyWith(minute: 0, second: 0, millisecond: 0)
          : DateTime(initialDay!.year, initialDay!.month, initialDay!.day, 9),
    );
    final duration = useState(60);
    final notes = useTextEditingController();
    final busy = useState(false);
    final loaded = useRef(false);

    if (isEditing && existing != null && !loaded.value) {
      loaded.value = true;
      clientId.value = existing.clientId;
      start.value = existing.start;
      duration.value = existing.durationMinutes;
      notes.text = existing.notes;
    }

    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: start.value,
        firstDate: DateTime(DateTime.now().year - 1),
        lastDate: DateTime(DateTime.now().year + 3),
      );
      if (picked != null) {
        start.value = DateTime(
          picked.year,
          picked.month,
          picked.day,
          start.value.hour,
          start.value.minute,
        );
      }
    }

    Future<void> pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(start.value),
      );
      if (picked != null) {
        start.value = DateTime(
          start.value.year,
          start.value.month,
          start.value.day,
          picked.hour,
          picked.minute,
        );
      }
    }

    Appointment? build() {
      final id = clientId.value;
      if (id == null) return null;
      Client? client;
      for (final c in clients) {
        if (c.id == id) client = c;
      }
      if (client == null) return null;
      return Appointment(
        id: appointmentId ?? '',
        clientId: client.id,
        clientName: client.name,
        clientAddress: client.address,
        start: start.value,
        durationMinutes: duration.value,
        notes: notes.text.trim(),
      );
    }

    Future<void> save() async {
      final appt = build();
      if (appt == null) return;
      busy.value = true;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(repositoryProvider).upsertAppointment(appt);
        if (context.mounted) context.pop();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
      } finally {
        busy.value = false;
      }
    }

    void addToPhoneCalendar() {
      final appt = build();
      if (appt == null) return;
      Add2Calendar.addEvent2Cal(
        Event(
          title: 'Trim — ${appt.clientName}',
          description: appt.notes,
          location: appt.clientAddress,
          startDate: appt.start,
          endDate: appt.end,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit appointment' : 'New appointment'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () async {
                await ref
                    .read(repositoryProvider)
                    .deleteAppointment(appointmentId!);
                if (context.mounted) context.pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text('Client', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: clientId.value,
            hint: const Text('Choose a client'),
            items: [
              for (final c in clients)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => clientId.value = v,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pickDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(DateFormat.yMMMd().format(start.value)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pickTime,
                  icon: const Icon(Icons.schedule_outlined, size: 18),
                  label: Text(DateFormat.jm().format(start.value)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Duration', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: duration.value > 15
                    ? () => duration.value -= 15
                    : null,
              ),
              SizedBox(
                width: 80,
                child: Text(
                  '${duration.value} min',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: duration.value < 240
                    ? () => duration.value += 15
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Notes', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: notes,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Horses to do, gate code, anything to bring…',
            ),
          ),
          const SizedBox(height: 18),
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
                : Text(isEditing ? 'Save changes' : 'Add appointment'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: addToPhoneCalendar,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: const Text('Add to phone calendar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
