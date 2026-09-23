import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/error_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../providers/admin_provider.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/widgets/search_bar.dart';
import 'manage_materials_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _selectedRoleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => Provider.of<AdminProvider>(context, listen: false).loadUsers());
  }

  void _showUserDialog({User? user}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = user != null;
    final emailController = TextEditingController(text: user?.email ?? '');
    // If editing, try to show stored password if available (user.password field I added)
    final passwordController =
        TextEditingController(text: user?.password ?? '');
    final nameController = TextEditingController(text: user?.displayName ?? '');
    ValueNotifier<UserRole> selectedRoleNotifier =
        ValueNotifier(user?.role ?? UserRole.student);
    bool isObscure = true;

    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit User' : l10n.createUserTitle),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: l10n.email),
                      enabled: !isEditing,
                      keyboardType: TextInputType.emailAddress,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                          labelText: l10n.password,
                          suffixIcon: IconButton(
                            icon: Icon(isObscure
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                isObscure = !isObscure;
                              });
                            },
                          )),
                      obscureText: isObscure,
                      keyboardType: TextInputType.visiblePassword,
                      validator: (value) {
                        if ((!isEditing ||
                                (value != null && value.isNotEmpty)) &&
                            (value == null || value.length < 6)) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.displayName),
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<UserRole>(
                      valueListenable: selectedRoleNotifier,
                      builder: (context, selectedRole, child) {
                        return DropdownButtonFormField<UserRole>(
                          value: selectedRole,
                          decoration: InputDecoration(labelText: l10n.role),
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(_getRoleName(role, l10n)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              selectedRoleNotifier.value = value;
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      if (isEditing) {
                        await Provider.of<AdminProvider>(context, listen: false)
                            .updateUser(
                          uid: user.id,
                          currentStoredPassword:
                              user.password ?? '', // Hope it's stored!
                          currentEmail: user.email ??
                              emailController.text, // Use stored or input
                          newPassword: passwordController.text != user.password
                              ? passwordController.text
                              : null,
                          newDisplayName: nameController.text,
                          newRole: selectedRoleNotifier.value,
                        );
                      } else {
                        await Provider.of<AdminProvider>(context, listen: false)
                            .createUser(
                                emailController.text,
                                passwordController.text,
                                nameController.text,
                                selectedRoleNotifier.value);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        AppErrorHandler.showErrorToast(context, e);
                      }
                    }
                  }
                },
                child: Consumer<AdminProvider>(
                  builder: (context, admin, child) {
                    if (admin.isLoading) {
                      return const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    return Text(isEditing ? l10n.save : l10n.create);
                  },
                ),
              ),
            ],
          );
        });
      },
    );
  }

  void _confirmDelete(User user) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUserTitle),
        content: Text(l10n.deleteUserContent(user.displayName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () async {
                try {
                  await Provider.of<AdminProvider>(context, listen: false)
                      .deleteUser(
                          user.id, user.email ?? '', user.password ?? '');
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(
                        context); // Close dialog first if needed or just show snackbar
                    AppErrorHandler.showErrorToast(context, e);
                  }
                }
              },
              child:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showUserInfoDialog(User user) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.userInfo),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(l10n.displayName, user.displayName),
            _buildInfoRow(l10n.username, user.username),
            _buildInfoRow(l10n.email, user.email ?? 'N/A'),
            _buildInfoRow(l10n.role, _getRoleName(user.role, l10n)),
            if (user.password != null)
              _buildInfoRow(l10n.password, user.password!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  void _showUsersListDialog(
      String title, List<User> listUsers, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.people, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: listUsers.isEmpty
                ? Center(
                    child: Text(l10n.noResults,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: listUsers.length,
                    itemBuilder: (context, index) {
                      final user = listUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.role == UserRole.admin
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.accent.withOpacity(0.1),
                          child: Icon(
                            user.role == UserRole.admin
                                ? Icons.admin_panel_settings
                                : Icons.school,
                            color: user.role == UserRole.admin
                                ? AppColors.primary
                                : AppColors.accent,
                          ),
                        ),
                        title: Text(user.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('@${user.username}'),
                        onTap: () {
                          Navigator.pop(context);
                          _showUserInfoDialog(user);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.done),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Consumer<AdminProvider>(
        builder: (context, admin, child) {
          if (admin.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppErrorHandler.showErrorToast(context, admin.error!);
              admin.clearError();
            });
          }

          if (admin.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = admin.users;
          final stats = admin.stats;

          return ResponsiveContainer(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Search and Filter Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        AppSearchBar(
                          controller: _searchController,
                          hintText: l10n.search,
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: Text(l10n.all),
                                selected: _selectedRoleFilter == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedRoleFilter = null;
                                  });
                                },
                                selectedColor: AppColors.primary.withOpacity(0.2),
                                checkmarkColor: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              ...UserRole.values.map((role) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    label: Text(_getRoleName(role, l10n)),
                                    selected: _selectedRoleFilter == role,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedRoleFilter =
                                            selected ? role : null;
                                      });
                                    },
                                    selectedColor:
                                        AppColors.primary.withOpacity(0.2),
                                    checkmarkColor: AppColors.primary,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Statistics Section
                  if (stats.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio:
                            0.9, // Lower value = more vertical space
                        children: [
                          _buildStatCard(
                              l10n.totalUsers,
                              '${stats['totalUsers'] ?? 0}',
                              Icons.people, onTap: () {
                            _showUsersListDialog(l10n.totalUsers, users, l10n);
                          }),
                          _buildStatCard(
                              l10n.statStudents,
                              '${stats['students'] ?? 0}',
                              Icons.school, onTap: () {
                            _showUsersListDialog(
                                l10n.statStudents,
                                users
                                    .where((u) => u.role == UserRole.student)
                                    .toList(),
                                l10n);
                          }),
                          _buildStatCard(
                              l10n.statAdmins,
                              '${stats['admins'] ?? 0}',
                              Icons.admin_panel_settings, onTap: () {
                            _showUsersListDialog(
                                l10n.statAdmins,
                                users
                                    .where((u) => u.role == UserRole.admin)
                                    .toList(),
                                l10n);
                          }),
                          _buildStatCard(
                              l10n.statMaterials,
                              '${stats['materials'] ?? 0}',
                              Icons.library_books, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ManageMaterialsScreen()),
                            );
                          }),
                        ],
                      ),
                    ),

                  Builder(builder: (context) {
                    final filteredUsers = users.where((user) {
                      final matchesSearch = user.displayName
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase()) ||
                          user.email!
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase()) ||
                          user.username
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase());
                      final matchesRole = _selectedRoleFilter == null ||
                          user.role == _selectedRoleFilter;
                      return matchesSearch && matchesRole;
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 64,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(l10n.noResults,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return InkWell(
                          onTap: () => _showUserInfoDialog(user),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: user.role == UserRole.admin
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.accent.withOpacity(0.1),
                                  child: Icon(
                                    user.role == UserRole.admin
                                        ? Icons.admin_panel_settings
                                        : Icons.school,
                                    color: user.role == UserRole.admin
                                        ? AppColors.primary
                                        : AppColors.accent,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '@${user.username} • ${_getRoleName(user.role, l10n)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                      if (user.password != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '${l10n.password}: ${user.password}',
                                            style: TextStyle(
                                              color: AppColors.primary
                                                  .withOpacity(0.6),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _showUserDialog(user: user),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => _confirmDelete(user),
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withOpacity(0.8),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleName(UserRole role, AppLocalizations l10n) {
    switch (role) {
      case UserRole.admin:
        return l10n.roleAdmin;
      case UserRole.student:
        return l10n.roleStudent;
    }
  }
}
