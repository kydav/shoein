import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoein/core/models/client.dart';
import 'package:shoein/core/providers/data_providers.dart';
import 'package:shoein/core/services/geocoding_service.dart';

class ClientFormScreen extends HookConsumerWidget {
  final String? clientId;
  const ClientFormScreen({this.clientId, super.key});

  bool get isEditing => clientId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = isEditing
        ? ref.watch(clientProvider(clientId!)).value
        : null;

    final name = useTextEditingController(text: existing?.name ?? '');
    final phone = useTextEditingController(text: existing?.phone ?? '');
    final email = useTextEditingController(text: existing?.email ?? '');
    final address = useTextEditingController(text: existing?.address ?? '');
    final notes = useTextEditingController(text: existing?.notes ?? '');
    final busy = useState(false);

    // Prefill once the async existing client arrives (edit mode).
    final loaded = useRef(false);
    if (isEditing && existing != null && !loaded.value) {
      loaded.value = true;
      name.text = existing.name;
      phone.text = existing.phone;
      email.text = existing.email;
      address.text = existing.address;
      notes.text = existing.notes;
    }

    Future<void> save() async {
      if (name.text.trim().isEmpty) return;
      busy.value = true;
      final messenger = ScaffoldMessenger.of(context);
      try {
        // Re-geocode when the address changed (or is new).
        double? lat = existing?.lat;
        double? lng = existing?.lng;
        final addr = address.text.trim();
        if (addr.isNotEmpty && addr != existing?.address) {
          final geo = await geocodeAddress(addr);
          lat = geo?.lat;
          lng = geo?.lng;
        } else if (addr.isEmpty) {
          lat = null;
          lng = null;
        }

        final client = Client(
          id: clientId ?? '',
          name: name.text.trim(),
          phone: phone.text.trim(),
          email: email.text.trim(),
          address: addr,
          lat: lat,
          lng: lng,
          notes: notes.text.trim(),
        );
        await ref.read(repositoryProvider).upsertClient(client);
        if (addr.isNotEmpty && lat == null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                "Saved — couldn't pin the address on the map, but everything else is stored.",
              ),
            ),
          );
        }
        if (context.mounted) context.pop();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
      } finally {
        busy.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit client' : 'New client')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _Field(
            label: 'Name',
            controller: name,
            textCapitalization: TextCapitalization.words,
          ),
          _Field(
            label: 'Phone',
            controller: phone,
            keyboardType: TextInputType.phone,
          ),
          _Field(
            label: 'Email',
            controller: email,
            keyboardType: TextInputType.emailAddress,
          ),
          _Field(
            label: 'Address',
            controller: address,
            hint: 'Street, city — used for the map',
            maxLines: 2,
          ),
          _Field(
            label: 'Notes',
            controller: notes,
            hint: 'Gate codes, preferences…',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
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
                : Text(isEditing ? 'Save changes' : 'Add client'),
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
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
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
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }
}
