import 'package:uuid/uuid.dart';

enum ContentType {
  pdf,
  video,
  audio,
}

class ContentItem {
  final String id;
  final String title;
  final String description;
  final ContentType type;
  final String url;
  final DateTime createdAt;

  ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.createdAt,
  });

  factory ContentItem.create({
    required String title,
    required String description,
    required ContentType type,
    required String url,
  }) {
    return ContentItem(
      id: const Uuid().v4(),
      title: title,
      description: description,
      type: type,
      url: url,
      createdAt: DateTime.now(),
    );
  }

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ContentType.values.firstWhere((e) => e.name == json['type']),
      url: json['url'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Subject {
  final String id;
  final String title;
  final List<ContentItem> contents;

  Subject({
    required this.id,
    required this.title,
    required this.contents,
  });

  factory Subject.create({required String title}) {
    return Subject(
      id: const Uuid().v4(),
      title: title,
      contents: [],
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      title: json['title'],
      contents: (json['contents'] as List)
          .map((e) => ContentItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'contents': contents.map((e) => e.toJson()).toList(),
    };
  }

  Subject copyWith({
    String? id,
    String? title,
    List<ContentItem>? contents,
  }) {
    return Subject(
      id: id ?? this.id,
      title: title ?? this.title,
      contents: contents ?? this.contents,
    );
  }
}

class CourseMaterial {
  final String id;
  final String title;
  final String description;
  final List<Subject> subjects;
  final List<String> assignedUserIds;
  final DateTime createdAt;

  CourseMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.subjects,
    required this.assignedUserIds,
    required this.createdAt,
  });

  factory CourseMaterial.create({
    required String title,
    required String description,
  }) {
    return CourseMaterial(
      id: const Uuid().v4(),
      title: title,
      description: description,
      subjects: [],
      assignedUserIds: [],
      createdAt: DateTime.now(),
    );
  }

  factory CourseMaterial.fromJson(Map<String, dynamic> json, {String? id}) {
    return CourseMaterial(
      id: json['id'] ?? id ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subjects: (json['subjects'] as List? ?? [])
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList(),
      assignedUserIds: List<String>.from(json['assignedUserIds'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'assignedUserIds': assignedUserIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CourseMaterial copyWith({
    String? id,
    String? title,
    String? description,
    List<Subject>? subjects,
    List<String>? assignedUserIds,
    DateTime? createdAt,
  }) {
    return CourseMaterial(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
