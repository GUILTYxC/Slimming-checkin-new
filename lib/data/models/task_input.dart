/// Lightweight value object used by the plan form when creating or editing a
/// plan's task list. [id] is null for a task that has not been persisted yet.
class TaskInput {
  const TaskInput({
    this.id,
    required this.title,
    this.targetCount = 1,
    this.unit,
  });

  final int? id;
  final String title;

  /// 1 = checkbox; >1 = dosage (e.g. 8 cups of water).
  final int targetCount;
  final String? unit;

  TaskInput copyWith({String? title, int? targetCount, String? unit}) =>
      TaskInput(
        id: id,
        title: title ?? this.title,
        targetCount: targetCount ?? this.targetCount,
        unit: unit ?? this.unit,
      );
}
