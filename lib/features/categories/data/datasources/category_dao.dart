import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../../domain/models/category.dart' as domain;

part 'category_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<domain.Category>> watchCategories() {
    return select(categoriesTable).watch().map((rows) => rows.map(_mapToDomain).toList());
  }

  Future<List<domain.Category>> getAllCategories() {
    return select(categoriesTable).get().then((rows) => rows.map(_mapToDomain).toList());
  }

  Future<domain.Category?> getCategoryById(String id) {
    return (select(categoriesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull()
        .then((r) => r != null ? _mapToDomain(r) : null);
  }

  Future<void> insertCategory(domain.Category cat) {
    return into(categoriesTable).insert(CategoriesTableCompanion(
      id: Value(cat.id),
      name: Value(cat.name),
      type: Value(cat.type.name),
      color: Value(cat.color),
      icon: Value(cat.icon),
      createdAt: Value(cat.createdAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> updateCategory(domain.Category cat) {
    return update(categoriesTable).replace(CategoriesTableCompanion(
      id: Value(cat.id),
      name: Value(cat.name),
      type: Value(cat.type.name),
      color: Value(cat.color),
      icon: Value(cat.icon),
      createdAt: Value(cat.createdAt.millisecondsSinceEpoch),
    ));
  }

  Future<void> deleteCategory(String id) {
    return (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
  }

  domain.Category _mapToDomain(CategoriesTableData r) {
    return domain.Category(
      id: r.id,
      name: r.name,
      type: domain.CategoryType.fromString(r.type),
      color: r.color,
      icon: r.icon,
      createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
    );
  }
}
