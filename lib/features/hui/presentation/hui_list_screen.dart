import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_hui_app/core/providers/providers.dart';
import 'package:so_hui_app/common/widgets/hui_card.dart';
import 'package:so_hui_app/common/widgets/empty_state.dart';

final huiListProvider = FutureProvider((ref) async {
  final huiRepo = ref.watch(huiRepositoryProvider);
  return await huiRepo.getAllHuiGroups();
});

class HuiListScreen extends ConsumerWidget {
  const HuiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final huiList = ref.watch(huiListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách dây hụi'),
      ),
      body: huiList.when(
        data: (huiGroups) {
          if (huiGroups.isEmpty) {
            return EmptyState(
              message: 'Chưa có dây hụi nào\nHãy tạo dây hụi đầu tiên',
              icon: Icons.widgets,
              actionLabel: 'Tạo dây hụi',
              onAction: () => context.push('/hui/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(huiListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: huiGroups.length,
              itemBuilder: (context, index) {
                final hui = huiGroups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HuiCard(
                    huiGroup: hui,
                    onTap: () => context.push('/hui/${hui.id}'),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Lỗi: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hui/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo dây hụi'),
      ),
    );
  }
}
