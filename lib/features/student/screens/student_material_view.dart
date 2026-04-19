import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../admin/models/material_model.dart';
import '../../content_player/screens/video_screen.dart';
import '../../content_player/screens/pdf_screen.dart';
import '../../../../core/widgets/search_bar.dart';
import '../../../../core/widgets/responsive_container.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StudentMaterialView extends StatefulWidget {
  final CourseMaterial course;

  const StudentMaterialView({super.key, required this.course});

  @override
  State<StudentMaterialView> createState() => _StudentMaterialViewState();
}

class _StudentMaterialViewState extends State<StudentMaterialView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openContent(BuildContext context, ContentItem content) {
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
                  userId: 'Student Access',
                  title: content.title,
                )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
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
                final filteredSubjects =
                    widget.course.subjects.where((subject) {
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
                            color: AppColors.textSecondary.withOpacity(0.5)),
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
                    final filteredContents = subject.contents
                        .where((c) =>
                            c.title.toLowerCase().contains(query) ||
                            c.description.toLowerCase().contains(query) ||
                            subject.title.toLowerCase().contains(query))
                        .toList();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ExpansionTile(
                        initiallyExpanded: index == 0,
                        title: Text(subject.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        children: filteredContents.map((content) {
                          return ListTile(
                            leading: Icon(
                              content.type == ContentType.video
                                  ? Icons.play_circle_fill
                                  : content.type == ContentType.audio
                                      ? Icons.audio_file
                                      : Icons.picture_as_pdf,
                              color: AppColors.accent,
                            ),
                            title: Text(content.title),
                            subtitle: Text(content.description),
                            onTap: () => _openContent(context, content),
                          );
                        }).toList(),
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
  }
}
