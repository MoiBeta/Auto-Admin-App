import 'package:auto_admin_app/features/tasks/data/datasources/data_source.dart';
import 'package:auto_admin_app/features/tasks/data/datasources/firestore_data_source.dart';
import 'package:auto_admin_app/features/tasks/data/repositories/tasks_repository_impl.dart';
import 'package:auto_admin_app/features/tasks/domain/repository/tasks_repository.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/create_new_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/delete_task.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/get_all_tasks.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/update_task_instance.dart';
import 'package:auto_admin_app/features/tasks/domain/use_cases/update_task_template.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Provider<TasksDataSource> taskDataSourceProvider =
    Provider<TasksDataSource>((_) => FirestoreDataSource());

Provider<TasksRepository> taskRepositoryProvider = Provider<TasksRepository>(
    (ref) => TaskRepositoryImpl(ref.watch(taskDataSourceProvider)));

Provider<CreateNewTask> createNewTaskProvider = Provider<CreateNewTask>(
    (ref) => CreateNewTask(ref.watch(taskRepositoryProvider)));

Provider<DeleteTask> deleteTaskProvider = Provider<DeleteTask>(
    (ref) => DeleteTask(ref.watch(taskRepositoryProvider)));

Provider<GetAllTasks> getAllTasksProvider = Provider<GetAllTasks>(
    (ref) => GetAllTasks(ref.watch(taskRepositoryProvider)));

Provider<UpdateTaskTemplate> updateTaskTemplateProvider =
    Provider<UpdateTaskTemplate>(
        (ref) => UpdateTaskTemplate(ref.watch(taskRepositoryProvider)));

Provider<UpdateTaskInstance> updateTaskInstanceProvider =
    Provider<UpdateTaskInstance>(
        (ref) => UpdateTaskInstance(ref.watch(taskRepositoryProvider)));
