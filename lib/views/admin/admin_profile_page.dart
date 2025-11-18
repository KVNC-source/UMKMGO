import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.userRole != UserRole.admin) {
      return const Center(child: Text('Not authorized'));
    }

    final user = auth.currentUser;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.email ?? '-'),
            subtitle: Text('Role: ${auth.userRole.name}'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
