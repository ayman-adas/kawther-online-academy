import 'package:flutter/material.dart';
import '../../../../core/utils/error_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../models/material_model.dart';
import '../providers/admin_provider.dart';
import '../../../../core/widgets/responsive_container.dart';
import '../../../../core/widgets/search_bar.dart';
import 'material_detail_screen.dart';

class ManageMaterialsScreen extends StatefulWidget {
  const ManageMaterialsScreen({super.key});

  @override
  State<ManageMaterialsScreen> createState() => _ManageMaterialsScreenState();
}

class _ManageMaterialsScreenState extends State<ManageMaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.loadMaterials();
      adminProvider.loadUsers();
    });
  }

  void _showCreateCourseDialog({CourseMaterial? course}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = course != null;
    final titleController = TextEditingController(text: course?.title);
    final descriptionController =
        TextEditingController(text: course?.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? l10n.editCourse : l10n.createCourseTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: l10n.title),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.length < 5) {
                      return 'Title must be at least 5 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: l10n.description),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
              ],
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
                          .updateCourse(course.id, titleController.text,
                              descriptionController.text);
                    } else {
                      await Provider.of<AdminProvider>(context, listen: false)
                          .createCourse(
                              titleController.text, descriptionController.text);
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
                  return Text(isEditing ? l10n.update : l10n.create);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAssignDialog(CourseMaterial courseIdOnly) {
    final l10n = AppLocalizations.of(context)!;

    // Grab the current latest state to initialize the dialog
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final initialCourse = adminProvider.materials.firstWhere(
      (m) => m.id == courseIdOnly.id,
      orElse: () => courseIdOnly,
    );

    // Create a local copy of assigned IDs for the dialog state
    final Set<String> localAssignedIds =
        Set.from(initialCourse.assignedUserIds);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.assignTo(initialCourse.title)),
              content: SizedBox(
                width: double.maxFinite,
                child: Consumer<AdminProvider>(
                  builder: (context, admin, _) {
                    final students = admin.users
                        .where((u) => u.role == UserRole.student)
                        .toList();

                    if (students.isEmpty) {
                      return Text(l10n.noStudentsAvailable);
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isAssigned =
                            localAssignedIds.contains(student.id);

                        return CheckboxListTile(
                          title: Text(student.displayName),
                          subtitle: Text(student.username),
                          value: isAssigned,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                localAssignedIds.add(student.id);
                              } else {
                                localAssignedIds.remove(student.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Commit changes only on Done
                    try {
                      await Provider.of<AdminProvider>(context, listen: false)
                          .updateCourseAssignments(
                              initialCourse.id, localAssignedIds.toList());
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        AppErrorHandler.showErrorToast(context, e);
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
                      return Text(l10n.done);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCourse(CourseMaterial course) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCourse),
        content: Text(l10n.deleteCourseConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false)
                    .deleteCourse(course.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  AppErrorHandler.showErrorToast(context, e);
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
                return Text(l10n.delete,
                    style: const TextStyle(color: Colors.red));
              },
            ),
          ),
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
          if (admin.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final materials = admin.materials;

          return ResponsiveContainer(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: AppSearchBar(
                    controller: _searchController,
                    hintText: l10n.search,
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: Builder(builder: (context) {
                    final filteredMaterials = materials.where((m) {
                      return m.title
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase());
                    }).toList();

                    if (filteredMaterials.isEmpty) {
                      return Center(
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
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMaterials.length,
                      itemBuilder: (context, index) {
                        final material = filteredMaterials[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.class_,
                                  color: AppColors.primary),
                            ),
                            title: Text(material.title),
                            subtitle: Text(
                                '${l10n.subjectsCount(material.subjects.length)} • ${l10n.assignedToStudents(material.assignedUserIds.length)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.person_add_alt_1),
                                  tooltip: l10n.assignToStudentsTooltip,
                                  onPressed: () => _showAssignDialog(material),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showCreateCourseDialog(course: material);
                                    } else if (value == 'delete') {
                                      _confirmDeleteCourse(material);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit,
                                              size: 20, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text(l10n.edit),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete,
                                              size: 20, color: Colors.red),
                                          const SizedBox(width: 8),
                                          Text(l10n.delete),
                                        ],
                                      ),
                                    ),
                                  ],
                                  icon: const Icon(Icons.more_vert),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        MaterialDetailScreen(course: material)),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateCourseDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
