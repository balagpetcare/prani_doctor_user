import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pranidoctor_user/l10n/app_localizations.dart';

import '../../core/layout/shell_page_padding.dart';
import '../../routing/app_routes.dart';
import '../notifications/presentation/notifications_panel.dart';
import '../service_requests/data/service_request_dto.dart';
import '../service_requests/data/service_request_repository.dart';
import '../service_requests/presentation/service_request_status_chip.dart';

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: ShellPagePadding.page(context).copyWith(bottom: 0),
            child: Text(
              l10n.navInbox,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: l10n.appointmentsTitle),
              Tab(text: l10n.notificationsTitle),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [_AppointmentsTab(), NotificationsPanel()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsTab extends ConsumerWidget {
  const _AppointmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final segment = ref.watch(inboxSegmentProvider);
    final requestsAsync = ref.watch(serviceRequestListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _SegmentChip(
                label: l10n.segmentActive,
                selected: segment == InboxSegment.active,
                onSelected: () {
                  ref.read(inboxSegmentProvider.notifier).state =
                      InboxSegment.active;
                  ref.invalidate(serviceRequestListProvider);
                },
              ),
              _SegmentChip(
                label: l10n.segmentCompleted,
                selected: segment == InboxSegment.completed,
                onSelected: () {
                  ref.read(inboxSegmentProvider.notifier).state =
                      InboxSegment.completed;
                  ref.invalidate(serviceRequestListProvider);
                },
              ),
              _SegmentChip(
                label: l10n.segmentClosed,
                selected: segment == InboxSegment.closed,
                onSelected: () {
                  ref.read(inboxSegmentProvider.notifier).state =
                      InboxSegment.closed;
                  ref.invalidate(serviceRequestListProvider);
                },
              ),
              _SegmentChip(
                label: l10n.segmentAll,
                selected: segment == InboxSegment.all,
                onSelected: () {
                  ref.read(inboxSegmentProvider.notifier).state =
                      InboxSegment.all;
                  ref.invalidate(serviceRequestListProvider);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: requestsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (requests) {
              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.noAppointments),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go(AppRoutes.services),
                        child: Text(l10n.findDoctors),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(serviceRequestListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _AppointmentCard(request: request);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.request});

  final ServiceRequestDto request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        onTap: () => context.go(AppRoutes.serviceRequestDetail(request.id)),
        title: Text(request.animal?.name ?? l10n.appointmentDetails),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceTypeLabel(l10n, request.serviceType)),
            if (request.assigneeName != null)
              Text('${l10n.assignedDoctor}: ${request.assigneeName}')
            else
              Text(l10n.awaitingAssignment),
            Text(formatTimestamp(request.submittedAt ?? request.createdAt)),
          ],
        ),
        trailing: ServiceRequestStatusChip(status: request.status),
      ),
    );
  }
}
