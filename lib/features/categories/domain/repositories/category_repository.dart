import '../models/category.dart';

abstract class ICategoryRepository {
  Stream<List<Category>> watchAllCategories();
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(String id);
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
}
