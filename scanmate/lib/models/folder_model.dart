import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'folder_model.g.dart'; // Hive generator will create this

@HiveType(typeId: 1)
class FolderModel extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id; // Unique ID for the folder

  @HiveField(1)
  String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  String? parentFolderId; // ID of the parent folder (null if root level folder)

  FolderModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.parentFolderId,
  });

  @override
  List<Object?> get props => [id, name, createdAt, updatedAt, parentFolderId];
}
