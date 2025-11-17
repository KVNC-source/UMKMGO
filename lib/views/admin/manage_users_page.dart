import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:umkmgo/providers/auth_provider.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final _emailCtrl = TextEditingController();
  UserRole _role = UserRole.buyer;
  bool _saving = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _saving = true);
    await context.read<AuthProvider>().upsertUser(email, role: _role);
    setState(() => _saving = false);
    _emailCtrl.clear();
    _role = UserRole.buyer;
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.userRole != UserRole.admin) {
      return const Center(child: Text('Not authorized'));
    }

    final users = auth.allUsers..sort((a, b) => a.email.compareTo(b.email));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<UserRole>(
                value: _role,
                onChanged: (v) => setState(() => _role = v ?? UserRole.buyer),
                items: const [
                  DropdownMenuItem(value: UserRole.buyer, child: Text('Buyer')),
                  DropdownMenuItem(
                    value: UserRole.seller,
                    child: Text('Seller'),
                  ),
                  DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                ],
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saving ? null : () => _save(context),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: users.isEmpty
                ? const Center(child: Text('No users yet'))
                : ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = users[i];
                      return ListTile(
                        title: Text(u.email),
                        subtitle: Text(
                          'Role: ${u.role.name} • Seller status: ${u.sellerRequestStatus.name}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<UserRole>(
                              tooltip: 'Change role',
                              onSelected: (r) => context
                                  .read<AuthProvider>()
                                  .setUserRole(u.email, r),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: UserRole.buyer,
                                  child: Text('Set Buyer'),
                                ),
                                PopupMenuItem(
                                  value: UserRole.seller,
                                  child: Text('Set Seller'),
                                ),
                                PopupMenuItem(
                                  value: UserRole.admin,
                                  child: Text('Set Admin'),
                                ),
                              ],
                              icon: const Icon(Icons.admin_panel_settings),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete user?'),
                                    content: Text('Delete ${u.email}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  context.read<AuthProvider>().deleteUser(
                                    u.email,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
