abstract class TasksDataSource {
  Future<List<Task>> getAllTasks();
  Future<Task> createNewTask(TaskData newTaskData);
  Future<Task> editTask(TaskData newTaskData);
  Future<void> deleteTask(DeleteTaskData deleteTaskData);
}