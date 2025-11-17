import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';

class SellerRequestsPage extends StatelessWidget {
  const SellerRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.userRole != UserRole.admin) {
      return const Center(child: Text('Not authorized'));
    }

    final pending = auth.pendingSellerRequests
      ..sort(
        (a, b) =>
            a.sellerRequestDate?.compareTo(
              b.sellerRequestDate ?? a.sellerRequestDate ?? DateTime.now(),
            ) ??
            0,
      );

    if (pending.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final u = pending[i];
        return ListTile(
          title: Text(u.email),
          subtitle: Text('Requested at: ${u.sellerRequestDate ?? '-'}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: () => context
                    .read<AuthProvider>()
                    .rejectSellerRequest(u.email, message: 'Insufficient info'),
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('Reject'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () =>
                    context.read<AuthProvider>().approveSellerRequest(u.email),
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
              ),
            ],
          ),
        );
      },
    );
  }
}
