import 'package:flutter/material.dart';
import '../../../../core/utils/error_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../models/material_model.dart';
import '../providers/admin_provider.dart';
import '../../../../core/widgets/responsive_container.dart';
import 'package:file_picker/file_picker.dart';
import '../../content_player/screens/video_screen.dart';
import '../../content_player/screens/pdf_screen.dart';
import '../../../../core/widgets/search_bar.dart';
// For checking path if needed, though PlatformFile uses bytes/path

class MaterialDetailScreen extends StatefulWidget {
  final CourseMaterial course;

  const MaterialDetailScreen({super.key, required this.course});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // We listen to the provider to get updates (e.g. after adding a subject)
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        // Find the latest version of the course from the provider
        final course = admin.materials.firstWhere(
          (m) => m.id == widget.course.id,
          orElse: () => widget.course,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(course.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.addSubject,
                onPressed: () => _showAddSubjectDialog(course),
              ),
            ],
          ),
          body: ResponsiveContainer(
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
                    final query = _searchController.text.toLowerCase();
                    final filteredSubjects = course.subjects.where((subject) {
                      final matchesSubject =
                          subject.title.toLowerCase().contains(query);
                      final matchesContent = subject.contents.any((content) =>
                          content.title.toLowerCase().contains(query) ||
                          content.description.toLowerCase().contains(query));
                      return matchesSubject || matchesContent;
                    }).toList();

                    if (filteredSubjects.isEmpty) {
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
                      itemCount: filteredSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = filteredSubjects[index];

                        // If searching, we might want to only show matching contents,
                        // but usually showing the whole subject is better for context.
                        final filteredContents = subject.contents
                            .where((c) =>
                                c.title.toLowerCase().contains(query) ||
                                c.description.toLowerCase().contains(query) ||
                                subject.title.toLowerCase().contains(query))
                            .toList();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ExpansionTile(
                            title: Text(subject.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditSubjectDialog(course, subject);
                                    } else if (value == 'delete') {
                                      _confirmDeleteSubject(course, subject);
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
                                // Retain standard expand icon behavior by adding it back optionally,
                                // or just rely on user tapping the row. ResponsiveContainer usually allows tap.
                                // ExpansionTile has an internal arrow that is hidden if trailing is provided.
                                // Let's add a custom one if we want, or just leave it.
                                // For detailed UX, adding a proper ExpandIcon is tricky without accessing State.
                                // A simple arrow icon that doesn't animate is a fair compromise,
                                // or just assuming users know to tap the header.
                                // Let's force an arrow icon for clarity.
                                const Icon(Icons.expand_more),
                              ],
                            ),
                            children: [
                              ...filteredContents.map((content) => ListTile(
                                    leading: Icon(
                                      _getContentIcon(content.type),
                                      color: AppColors.accent,
                                    ),
                                    title: Text(content.title),
                                    subtitle: Text(content.description),
                                    onTap: () => _openContent(content),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditContentDialog(
                                              course, subject, content);
                                        } else if (value == 'delete') {
                                          _confirmDeleteContent(
                                              course, subject, content);
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
                                      padding: EdgeInsets.zero,
                                      icon:
                                          const Icon(Icons.more_vert, size: 20),
                                    ),
                                  )),
                              ListTile(
                                leading: const Icon(Icons.add_circle_outline),
                                title: Text(l10n.addContent),
                                onTap: () =>
                                    _showAddContentDialog(course, subject),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openContent(ContentItem content) {
    if (content.type == ContentType.video ||
        content.type == ContentType.audio) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => VideoScreen(
                  videoUrl: content.url,
                  title: content.title,
                )),
      );
    } else if (content.type == ContentType.pdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PdfScreen(
                  pdfUrl: content.url,
                  userId: 'Admin Preview',
                  title: content.title,
                )),
      );
    }
  }

  IconData _getContentIcon(ContentType type) {
    switch (type) {
      case ContentType.video:
        return Icons.play_circle_fill;
      case ContentType.audio:
        return Icons.audio_file;
      case ContentType.pdf:
        return Icons.picture_as_pdf;
    }
  }

  void _showEditSubjectDialog(CourseMaterial course, Subject subject) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: subject.title);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editSubject),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleController,
            decoration: InputDecoration(labelText: l10n.subjectTitle),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              if (value.length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
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
              if (formKey.currentState!.validate()) {
                try {
                  await Provider.of<AdminProvider>(context, listen: false)
                      .updateSubject(
                          course.id, subject.id, titleController.text);
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
                return Text(l10n.update);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubject(CourseMaterial course, Subject subject) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSubject),
        content: Text(l10n.deleteSubjectConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false)
                    .deleteSubject(course.id, subject.id);
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

  void _showEditContentDialog(
      CourseMaterial course, Subject subject, ContentItem content) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: content.title);
    final descController = TextEditingController(text: content.description);
    final urlController = TextEditingController(text: content.url);
    ValueNotifier<ContentType> selectedTypeNotifier =
        ValueNotifier(content.type);
    ValueNotifier<PlatformFile?> selectedFileNotifier = ValueNotifier(null);
    // If it's a file (not just a link), ideally we know. But for now, we assume if type is not URL based...
    // Actually, 'url' field stores the download URL for files.
    // Let's assume default is "Keep existing".
    ValueNotifier<bool> isFileUploadNotifier =
        ValueNotifier(true); // Default to file/keep handling

    // If the existing content is a direct URL (not firebasestorage), maybe set isFileUpload to false?
    // Simple heuristic: if url contains 'firebasestorage', it's a file.
    if (!content.url.contains('firebasestorage')) {
      isFileUploadNotifier.value = false;
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.edit} ${content.title}'),
        content: SingleChildScrollView(
          child: Form(
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
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n.description),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<ContentType>(
                  valueListenable: selectedTypeNotifier,
                  builder: (context, selectedType, child) {
                    return DropdownButtonFormField<ContentType>(
                      value: selectedType,
                      decoration: InputDecoration(labelText: l10n.type),
                      items: ContentType.values.map((t) {
                        return DropdownMenuItem(
                            value: t, child: Text(t.name.toUpperCase()));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          selectedTypeNotifier.value = v;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: isFileUploadNotifier,
                  builder: (context, isFileUpload, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.url),
                        Switch(
                          value: isFileUpload,
                          onChanged: (val) {
                            isFileUploadNotifier.value = val;
                            if (val) {
                              urlController.clear();
                            } else {
                              selectedFileNotifier.value = null;
                              // If switching back to URL, restore original if it wasn't a file?
                              // Or leaves empty.
                            }
                          },
                        ),
                        Text(l10n.uploadFileLabel),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: isFileUploadNotifier,
                  builder: (context, isFileUpload, _) {
                    if (isFileUpload) {
                      return ValueListenableBuilder<PlatformFile?>(
                        valueListenable: selectedFileNotifier,
                        builder: (context, file, _) {
                          return Column(
                            children: [
                              if (file == null) ...[
                                Text(l10n.fileSelected('Current File'),
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic)),
                                const SizedBox(height: 8),
                              ],
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final allowedExtensions =
                                      selectedTypeNotifier.value ==
                                              ContentType.pdf
                                          ? ['pdf']
                                          : selectedTypeNotifier.value ==
                                                  ContentType.video
                                              ? ['mp4', 'mov', 'avi']
                                              : ['mp3', 'wav', 'm4a'];
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: allowedExtensions,
                                  );
                                  if (result != null) {
                                    selectedFileNotifier.value =
                                        result.files.first;
                                  }
                                },
                                icon: const Icon(Icons.attach_file),
                                label: Text(l10n.changeFile),
                              ),
                              if (file != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    l10n.fileSelected(file.name),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    } else {
                      return TextFormField(
                        controller: urlController,
                        decoration: InputDecoration(labelText: l10n.url),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (isFileUploadNotifier.value) {
                            return null;
                          }
                          if (value == null || value.isEmpty) {
                            return 'Please enter a URL';
                          }
                          if (!Uri.parse(value).isAbsolute ||
                              (!value.startsWith('http://') &&
                                  !value.startsWith('https://'))) {
                            return 'Please enter a valid web URL';
                          }
                          return null;
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          Consumer<AdminProvider>(
            builder: (context, admin, child) {
              if (admin.isLoading) {
                return const CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      await Provider.of<AdminProvider>(context, listen: false)
                          .updateContent(
                        course.id,
                        subject.id,
                        content.id,
                        titleController.text,
                        descController.text,
                        selectedTypeNotifier.value,
                        url: isFileUploadNotifier.value
                            ? null
                            : urlController.text,
                        file: selectedFileNotifier.value,
                        currentUrl: content.url,
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        AppErrorHandler.showErrorToast(context, e);
                      }
                    }
                  }
                },
                child: Text(l10n.update),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteContent(
      CourseMaterial course, Subject subject, ContentItem content) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false)
                    .deleteContent(course.id, subject.id, content.id);
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

  void _showAddSubjectDialog(CourseMaterial course) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addSubject),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleController,
            decoration: InputDecoration(labelText: l10n.subjectTitle),
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              if (value.length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
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
              if (formKey.currentState!.validate()) {
                try {
                  await Provider.of<AdminProvider>(context, listen: false)
                      .addSubject(course.id, titleController.text);
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
                return Text(l10n.add);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContentDialog(CourseMaterial course, Subject subject) {
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController();
    ValueNotifier<ContentType> selectedTypeNotifier =
        ValueNotifier(ContentType.pdf);
    ValueNotifier<PlatformFile?> selectedFileNotifier = ValueNotifier(null);
    ValueNotifier<bool> isFileUploadNotifier =
        ValueNotifier(false); // Toggle between URL and File

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addContentTo(subject.title)),
        content: SingleChildScrollView(
          child: Form(
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
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(labelText: l10n.description),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<ContentType>(
                  valueListenable: selectedTypeNotifier,
                  builder: (context, selectedType, child) {
                    return DropdownButtonFormField<ContentType>(
                      value: selectedType,
                      decoration: InputDecoration(labelText: l10n.type),
                      items: ContentType.values.map((t) {
                        return DropdownMenuItem(
                            value: t, child: Text(t.name.toUpperCase()));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          selectedTypeNotifier.value = v;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Toggle Switch
                ValueListenableBuilder<bool>(
                  valueListenable: isFileUploadNotifier,
                  builder: (context, isFileUpload, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.url),
                        Switch(
                          value: isFileUpload,
                          onChanged: (val) {
                            isFileUploadNotifier.value = val;
                            // Clear other field
                            if (val) {
                              urlController.clear();
                            } else {
                              selectedFileNotifier.value = null;
                            }
                          },
                        ),
                        Text(l10n.uploadFileLabel), // TODO: Localize
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                ValueListenableBuilder<bool>(
                  valueListenable: isFileUploadNotifier,
                  builder: (context, isFileUpload, _) {
                    if (isFileUpload) {
                      // File Picker UI
                      return ValueListenableBuilder<PlatformFile?>(
                        valueListenable: selectedFileNotifier,
                        builder: (context, file, _) {
                          return Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final allowedExtensions =
                                      selectedTypeNotifier.value ==
                                              ContentType.pdf
                                          ? ['pdf']
                                          : selectedTypeNotifier.value ==
                                                  ContentType.video
                                              ? ['mp4', 'mov', 'avi']
                                              : ['mp3', 'wav', 'm4a'];
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: allowedExtensions,
                                  );
                                  if (result != null) {
                                    selectedFileNotifier.value =
                                        result.files.first;
                                    // Auto-fill title if empty
                                    if (titleController.text.isEmpty) {
                                      titleController.text =
                                          result.files.first.name;
                                    }
                                  }
                                },
                                icon: const Icon(Icons.attach_file),
                                label: Text(file == null
                                    ? l10n.selectFile
                                    : l10n.changeFile),
                              ),
                              if (file != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    l10n.fileSelected(file.name),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              if (file == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    l10n.noFileSelected,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    } else {
                      // URL Input
                      return TextFormField(
                        controller: urlController,
                        decoration: InputDecoration(labelText: l10n.url),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (isFileUploadNotifier.value) {
                            return null; // Ignore if uploading file
                          }
                          if (value == null || value.isEmpty) {
                            return 'Please enter a URL';
                          }
                          final uri = Uri.tryParse(value);
                          if (uri == null ||
                              !uri.isAbsolute ||
                              (!value.startsWith('http://') &&
                                  !value.startsWith('https://'))) {
                            return 'Please enter a valid web URL';
                          }
                          return null;
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          Consumer<AdminProvider>(
            builder: (context, admin, child) {
              if (admin.isLoading) {
                return const CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: () async {
                  if (isFileUploadNotifier.value &&
                      selectedFileNotifier.value == null) {
                    AppErrorHandler.showErrorToast(
                        context, l10n.pleaseSelectFile);
                    return;
                  }

                  if (formKey.currentState!.validate()) {
                    try {
                      await Provider.of<AdminProvider>(context, listen: false)
                          .addContent(
                        course.id,
                        subject.id,
                        titleController.text,
                        descController.text,
                        selectedTypeNotifier.value,
                        url: urlController.text.isNotEmpty
                            ? urlController.text
                            : null,
                        file: selectedFileNotifier.value,
                      );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        AppErrorHandler.showErrorToast(context, e);
                      }
                    }
                  }
                },
                child: Text(l10n.add),
              );
            },
          ),
        ],
      ),
    );
  }
}
