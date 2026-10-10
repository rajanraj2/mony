enum CategoryType {
  expense,
  income;

  static CategoryType fromString(String val) =>
      CategoryType.values.firstWhere((e) => e.name == val, orElse: () => CategoryType.expense);
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final int color;
  final String icon;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    int? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
