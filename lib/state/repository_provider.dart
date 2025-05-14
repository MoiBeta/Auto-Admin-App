import 'package:auto_admin_app/data/repositories/firestore_task_repository.dart';
import 'package:auto_admin_app/data/repositories/task_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'repository_provider.g.dart';

@riverpod
TaskRepository taskRepository(Ref ref) => FirestoreTaskRepository();