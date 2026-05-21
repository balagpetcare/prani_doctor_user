import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../data/service_request_repository.dart';
import 'service_request_status_chip.dart';

class ServiceRequestHistoryPage extends ConsumerWidget {
  const ServiceRequestHistoryPage({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final timelineAsync = ref.watch(serviceRequestTimelineProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appointmentHistory)),
      body: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (timeline) {
          if (timeline.events.isEmpty) {
            return Center(child: Text(l10n.noHistoryYet));
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(serviceRequestTimelineProvider(requestId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: timeline.events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = timeline.events[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(timelineEventLabel(l10n, event.eventType)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatTimestamp(event.createdAt)),
                        if (event.actorDisplayName != null &&
                            event.actorDisplayName!.isNotEmpty)
                          Text(event.actorDisplayName!),
                        if (event.note != null && event.note!.isNotEmpty)
                          Text(event.note!),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
