import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_dao.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final CategoryDao _dao;

  CategoryRepositoryImpl(this._dao);

  @override
  Stream<List<Category>> watchAllCategories() => _dao.watchCategories();

  @override
  Future<List<Category>> getAllCategories() => _dao.getAllCategories();

  @override
  Future<Category?> getCategoryById(String id) => _dao.getCategoryById(id);

  @override
  Future<void> createCategory(Category category) => _dao.insertCategory(category);

  @override
  Future<void> updateCategory(Category category) => _dao.updateCategory(category);

  @override
  Future<void> deleteCategory(String id) => _dao.deleteCategory(id);
}
