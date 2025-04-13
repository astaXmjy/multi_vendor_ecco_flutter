// lib/core/models/category_model.dart
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final ParentDetails? parentDetails;
  final bool isActive;
  final bool isFeatured;
  final int productCount;
  final int childrenCount;
  final int menuOrder;
  final String? imageUrl;
  final String? createdAt;
  final List<CategoryModel> children;
  final int level;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.parentDetails,
    required this.isActive,
    required this.isFeatured,
    required this.productCount,
    required this.childrenCount,
    required this.menuOrder,
    this.imageUrl,
    this.createdAt,
    this.children = const [],
    this.level = 0,
  });

  // Parse a flat category list
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parentId: json['parent_id'],
      parentDetails: json['parent_details'] != null
          ? ParentDetails.fromJson(json['parent_details'])
          : null,
      isActive: json['is_active'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      productCount: json['product_count'] ?? 0,
      childrenCount: json['children_count'] ?? 0,
      menuOrder: json['menu_order'] ?? 0,
      imageUrl: json['image_url'],
      createdAt: json['created_at'],
      level: json['level'] ?? 0,
    );
  }

  // Parse from the tree structure API
  factory CategoryModel.fromTreeJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parentId: json['parent_id'],
      isActive: json['is_active'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      productCount: json['product_count'] ?? 0,
      childrenCount: (json['children'] as List?)?.length ?? 0,
      menuOrder: json['menu_order'] ?? 0,
      imageUrl: json['image_url'],
      level: json['level'] ?? 0,
      children: (json['children'] as List?)
              ?.map((child) => CategoryModel.fromTreeJson(child))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'parent_id': parentId,
      'parent_details': parentDetails?.toJson(),
      'is_active': isActive,
      'is_featured': isFeatured,
      'product_count': productCount,
      'children_count': childrenCount,
      'menu_order': menuOrder,
      'image_url': imageUrl,
      'created_at': createdAt,
      'children': children.map((child) => child.toJson()).toList(),
      'level': level,
    };
  }
}

class ParentDetails {
  final String id;
  final String name;
  final String slug;

  ParentDetails({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory ParentDetails.fromJson(Map<String, dynamic> json) {
    return ParentDetails(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }
}
