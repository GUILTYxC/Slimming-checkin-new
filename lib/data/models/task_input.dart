/// Lightweight value object used by the plan form when creating or editing a
/// plan's task list. [id] is null for a task that has not been persisted yet.
class TaskInput {
  const TaskInput({this.id, required this.title});

  final int? id;
  final String title;

  TaskInput copyWith({String? title}) =>
      TaskInput(id: id, title: title ?? this.title);
}
