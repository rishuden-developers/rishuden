class Quest {
  final String id;
  final String subjectName;
  final String taskType;
  final DateTime deadline;
  final String description;
  final DateTime createdAt;
  final String createdBy;
  final List<String> participants;
  final bool isCompleted;

  Quest({
    required this.id,
    required this.subjectName,
    required this.taskType,
    required this.deadline,
    required this.description,
    required this.createdAt,
    required this.createdBy,
    this.participants = const [],
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectName': subjectName,
      'taskType': taskType,
      'deadline': deadline.toIso8601String(),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'participants': participants,
      'isCompleted': isCompleted,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    return Quest(
      id: map['id'],
      subjectName: map['subjectName'],
      taskType: map['taskType'],
      deadline: DateTime.parse(map['deadline']),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'],
      participants: List<String>.from(map['participants'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Quest copyWith({
    String? id,
    String? subjectName,
    String? taskType,
    DateTime? deadline,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    List<String>? participants,
    bool? isCompleted,
  }) {
    return Quest(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      taskType: taskType ?? this.taskType,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      participants: participants ?? this.participants,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
