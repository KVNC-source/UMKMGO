// lib/views/admin/manage_users_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  // --- Kontroler untuk Form "Create User" ---
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  UserRole _role = UserRole.buyer;
  bool _isCreating = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // --- Fungsi untuk membuat pengguna baru ---
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm User Creation'),
        content: Text(
            'Create new user with email "${_emailCtrl.text}" and role "${_role.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Create User')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCreating = true);

    try {
      await authProvider.adminCreateUser(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        role: _role,
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('User created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState?.reset();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      setState(() {
        _role = UserRole.buyer;
      });
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  // --- Fungsi untuk menampilkan dialog edit pengguna ---
  void _showEditUserDialog(AppUser user) {
    final editNameCtrl = TextEditingController(text: user.name);
    final editPhoneCtrl = TextEditingController(text: user.phone);
    UserRole selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editPhoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Role:'),
                        DropdownButton<UserRole>(
                          value: selectedRole,
                          onChanged: (newRole) {
                            if (newRole != null) {
                              setDialogState(() {
                                selectedRole = newRole;
                              });
                            }
                          },
                          items: const [
                            DropdownMenuItem(value: UserRole.buyer, child: Text('Buyer')),
                            DropdownMenuItem(value: UserRole.seller, child: Text('Seller')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                    try {
                      await authProvider.updateUserAsAdmin(
                        uid: user.uid,
                        name: editNameCtrl.text.trim(),
                        phone: editPhoneCtrl.text.trim(),
                        role: selectedRole,
                      );
                      Navigator.of(ctx).pop(); // Tutup dialog
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('${user.email} updated successfully'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final users = context.watch<AuthProvider>().allUsers..sort((a, b) => a.email.compareTo(b.email));
    final currentUid = authProvider.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Form "Create User" di dalam ExpansionTile ---
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: const Icon(Icons.person_add_alt_1),
              title: const Text('Create New User', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Expand to fill form'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                          obscureText: true,
                          validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                                validator: (value) => (value == null || value.isEmpty) ? 'Name is required' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                                keyboardType: TextInputType.phone,
                                validator: (value) => (value == null || value.isEmpty) ? 'Phone is required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Assign Role:'),
                            const SizedBox(width: 12),
                            DropdownButton<UserRole>(
                              value: _role,
                              onChanged: (v) => setState(() => _role = v ?? UserRole.buyer),
                              items: const [
                                DropdownMenuItem(value: UserRole.buyer, child: Text('Buyer')),
                                DropdownMenuItem(value: UserRole.seller, child: Text('Seller')),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: _isCreating ? null : _createUser,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white),
                              child: _isCreating
                                  ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Create'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1),

          // --- Header untuk Daftar Pengguna dengan Tombol Refresh ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Existing Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh User List',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing data...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  await authProvider.refreshData();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Daftar Pengguna dengan Pull-to-Refresh ---
          Expanded(
            child: users.isEmpty
                ? const Center(child: Text('No users found'))
                : RefreshIndicator(
              onRefresh: () => authProvider.refreshData(),
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final u = users[i];
                  final isMe = u.uid == currentUid;
                  final isOtherAdmin = u.role == UserRole.admin && !isMe;
                  final isEditable = !isMe && !isOtherAdmin;

                  return ListTile(
                    dense: true,
                    onTap: isEditable ? () => _showEditUserDialog(u) : null,
                    leading: isEditable ? Icon(Icons.edit_note, color: Theme.of(context).colorScheme.primary) : null,
                    title: Text(u.email + (isMe ? ' (You)' : ''),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isEditable ? Theme.of(context).colorScheme.primary : null)),
                    subtitle: Text('Role: ${u.role.name} • Req: ${u.sellerRequestStatus.name}'),
                    trailing: isMe || isOtherAdmin
                        ? Chip(
                        label: Text(isMe ? "You" : "Admin", style: const TextStyle(fontSize: 12)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        backgroundColor: Colors.grey[300])
                        : IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete user?'),
                            content: Text('Delete ${u.email}? This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          authProvider.deleteUser(u.email);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
