import '../models/category_model.dart';

class CategoryService {
  // Sample categories for production inventory (meats/livestock)
  static final List<ProductCategory> _inventoryCategories = [
    ProductCategory(
      id: '1',
      name: 'Pigs (Live)',
      description: 'Live pigs in different weight categories',
      type: 'inventory',
      displayOrder: 1,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ProductCategory(
      id: '2',
      name: 'Cows (Live)',
      description: 'Live cows for roasting',
      type: 'inventory',
      displayOrder: 2,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ProductCategory(
      id: '3',
      name: 'Pork Belly',
      description: 'Pork belly cuts for lechon belly',
      type: 'inventory',
      displayOrder: 3,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ProductCategory(
      id: '4',
      name: 'Supplies',
      description: 'Cooking supplies and materials',
      type: 'inventory',
      displayOrder: 4,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  // Sample categories for POS products (finished goods)
  static final List<ProductCategory> _productCategories = [
    ProductCategory(
      id: '5',
      name: 'Whole Lechon',
      description: 'Whole roasted pig products',
      type: 'product',
      displayOrder: 1,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ProductCategory(
      id: '6',
      name: 'Lechon Belly',
      description: 'Boneless lechon belly products',
      type: 'product',
      displayOrder: 2,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ProductCategory(
      id: '7',
      name: 'Appetizers',
      description: 'Side dishes and appetizers',
      type: 'product',
      displayOrder: 3,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ProductCategory(
      id: '8',
      name: 'Desserts',
      description: 'Sweet treats and desserts',
      type: 'product',
      displayOrder: 4,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    ProductCategory(
      id: '9',
      name: 'Pastas',
      description: 'Pasta dishes',
      type: 'product',
      displayOrder: 5,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  static Future<List<ProductCategory>> getCategoriesByType(String type) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (type == 'inventory') {
      return List.from(_inventoryCategories.where((cat) => cat.isActive));
    } else {
      return List.from(_productCategories.where((cat) => cat.isActive));
    }
  }

  static Future<List<ProductCategory>> getAllCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final allCategories = [..._inventoryCategories, ..._productCategories];
    return List.from(allCategories.where((cat) => cat.isActive));
  }

  static Future<void> addCategory(ProductCategory category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (category.type == 'inventory') {
      _inventoryCategories.add(category);
    } else {
      _productCategories.add(category);
    }
  }

  static Future<void> updateCategory(ProductCategory category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (category.type == 'inventory') {
      final index = _inventoryCategories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _inventoryCategories[index] = category;
      }
    } else {
      final index = _productCategories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _productCategories[index] = category;
      }
    }
  }

  static Future<void> toggleCategoryStatus(String categoryId, String type) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (type == 'inventory') {
      final index = _inventoryCategories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        final category = _inventoryCategories[index];
        _inventoryCategories[index] = category.copyWith(
          isActive: !category.isActive,
          updatedAt: DateTime.now(),
        );
      }
    } else {
      final index = _productCategories.indexWhere((c) => c.id == categoryId);
      if (index != -1) {
        final category = _productCategories[index];
        _productCategories[index] = category.copyWith(
          isActive: !category.isActive,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  static Future<void> deleteCategory(String categoryId, String type) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (type == 'inventory') {
      _inventoryCategories.removeWhere((c) => c.id == categoryId);
    } else {
      _productCategories.removeWhere((c) => c.id == categoryId);
    }
  }

  static Future<int> getCategoryCount(String type) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (type == 'inventory') {
      return _inventoryCategories.where((cat) => cat.isActive).length;
    } else {
      return _productCategories.where((cat) => cat.isActive).length;
    }
  }
}