import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shoein/core/models/appointment.dart';
import 'package:shoein/core/presentation/widgets.dart';
import 'package:shoein/core/providers/access_providers.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final appts = ref.watch(appointmentsProvider).valueOrNull ?? const [];
    final readOnly = ref.watch(isReadOnlyProvider);

    List<Appointment> forDay(DateTime day) =>
        appts.where((a) => isSameDay(a.start, day)).toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    final dayAppts = forDay(_selectedDay);

    void newAppointment() {
      if (readOnly) {
        context.push('/paywall');
        return;
      }
      context.push('/schedule/new?day=${_selectedDay.toIso8601String()}');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 125),
        child: FloatingActionButton.extended(
          onPressed: newAppointment,
          icon: Icon(readOnly ? Icons.lock_outline_rounded : Icons.add),
          label: const Text('Appointment'),
        ),
      ),
      body: Column(
        children: [
          TableCalendar<Appointment>(
            firstDay: DateTime.utc(2022),
            lastDay: DateTime.utc(2032),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: forDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            onFormatChanged: (f) => setState(() => _format = f),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: kForge.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: kForge,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: kForgeDark,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: dayAppts.isEmpty
                ? Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Text(
                        'No appointments on ${DateFormat.MMMMd().format(_selectedDay)}.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      for (final a in dayAppts) _ApptTile(appointment: a),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ApptTile extends StatelessWidget {
  final Appointment appointment;
  const _ApptTile({required this.appointment});

  void _addToPhoneCalendar() {
    Add2Calendar.addEvent2Cal(
      Event(
        title: 'Trim — ${appointment.clientName}',
        description: appointment.notes,
        location: appointment.clientAddress,
        startDate: appointment.start,
        endDate: appointment.end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: () => context.push('/schedule/${appointment.id}/edit'),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.jm().format(appointment.start),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: kForge),
                ),
                Text(
                  '${appointment.durationMinutes}m',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.clientName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (appointment.notes.isNotEmpty)
                    Text(
                      appointment.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.event_available_outlined, color: kForge),
              tooltip: 'Add to phone calendar',
              onPressed: _addToPhoneCalendar,
            ),
          ],
        ),
      ),
    );
  }
}
