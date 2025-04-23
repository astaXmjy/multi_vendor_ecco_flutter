// lib/core/models/product_model.dart
class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String category;
  final BrandModel brand;
  final String regularPrice;
  final String salePrice;
  final int stockQuantity;
  final bool isActive;
  final bool isFeatured;
  final List<ImageModel> images;
  final String createdAt;
  final SellerModel? sellerInfo;
  final bool isWishlisted;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.category,
    required this.brand,
    required this.regularPrice,
    required this.salePrice,
    required this.stockQuantity,
    required this.isActive,
    required this.isFeatured,
    required this.images,
    required this.createdAt,
    this.sellerInfo,
    this.isWishlisted = false,
  });

  // Create a copy of the product with modified properties
  ProductModel copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? category,
    BrandModel? brand,
    String? regularPrice,
    String? salePrice,
    int? stockQuantity,
    bool? isActive,
    bool? isFeatured,
    List<ImageModel>? images,
    String? createdAt,
    SellerModel? sellerInfo,
    bool? isWishlisted,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      regularPrice: regularPrice ?? this.regularPrice,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      sellerInfo: sellerInfo ?? this.sellerInfo,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }

  // Get primary image URL or first image or default empty
  String get primaryImageUrl {
    try {
      // Find primary image first
      final primaryImage = images.firstWhere((img) => img.isPrimary);
      return primaryImage.imageUrl;
    } catch (_) {
      // If no primary image, return first image or empty string
      return images.isNotEmpty ? images.first.imageUrl : '';
    }
  }

  // Get discount percentage
  String get discountPercentage {
    try {
      final regular = double.parse(regularPrice);
      final sale = double.parse(salePrice);

      if (regular <= 0 || sale >= regular) return '';

      final discount = ((regular - sale) / regular * 100).round();
      return '$discount%';
    } catch (_) {
      return '';
    }
  }

  // Format price to ₹ format
  String get formattedRegularPrice => '₹$regularPrice';
  String get formattedSalePrice => '₹$salePrice';

  // Convert from JSON - useful when fetching from API
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse images
    List<ImageModel> imagesList = [];
    if (json['images'] != null) {
      imagesList = (json['images'] as List)
          .map((img) => ImageModel.fromJson(img))
          .toList();
    }

    // Parse brand
    BrandModel brandModel = BrandModel.empty();
    if (json['brand'] != null) {
      brandModel = BrandModel.fromJson(json['brand']);
    }

    // Parse seller info
    SellerModel? sellerModel;
    if (json['seller_info'] != null) {
      sellerModel = SellerModel.fromJson(json['seller_info']);
    }

    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      brand: brandModel,
      regularPrice: json['regular_price'] ?? '0.00',
      salePrice: json['sale_price'] ?? '0.00',
      stockQuantity: json['stock_quantity'] ?? 0,
      isActive: json['is_active'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      images: imagesList,
      createdAt: json['created_at'] ?? '',
      sellerInfo: sellerModel,
      isWishlisted: json['is_wishlisted'] ?? false,
    );
  }

  // Convert to JSON - useful when sending to API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'category': category,
      'brand': brand.toJson(),
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
      'is_featured': isFeatured,
      'images': images.map((img) => img.toJson()).toList(),
      'created_at': createdAt,
      'seller_info': sellerInfo?.toJson(),
      'is_wishlisted': isWishlisted,
    };
  }

  // Convert to a Map for use in ProductCard
  Map<String, dynamic> toCardMap() {
    return {
      'id': id.toString(),
      'name': name,
      'price': formattedSalePrice,
      'image': primaryImageUrl,
      'discount': discountPercentage,
    };
  }

  // Create an empty product model for placeholders
  factory ProductModel.empty() {
    return ProductModel(
      id: 0,
      name: '',
      slug: '',
      description: '',
      category: '',
      brand: BrandModel.empty(),
      regularPrice: '0.00',
      salePrice: '0.00',
      stockQuantity: 0,
      isActive: false,
      isFeatured: false,
      images: [],
      createdAt: '',
    );
  }
}

class ImageModel {
  final int id;
  final int product;
  final String imageUrl;
  final String altText;
  final bool isPrimary;
  final int sortOrder;
  final String createdAt;
  final String storagePath;

  ImageModel({
    required this.id,
    required this.product,
    required this.imageUrl,
    required this.altText,
    required this.isPrimary,
    required this.sortOrder,
    required this.createdAt,
    required this.storagePath,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      altText: json['alt_text'] ?? '',
      isPrimary: json['is_primary'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] ?? '',
      storagePath: json['storage_path'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'image_url': imageUrl,
      'alt_text': altText,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'storage_path': storagePath,
    };
  }
}

class BrandModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String logo;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.logo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      logo: json['logo'] ?? '',
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'logo': logo,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // Create an empty brand model for placeholders
  factory BrandModel.empty() {
    return BrandModel(
      id: 0,
      name: '',
      slug: '',
      description: '',
      logo: '',
      isActive: false,
      createdAt: '',
      updatedAt: '',
    );
  }
}

class SellerModel {
  final int id;
  final String userName;
  final String email;
  final String businessName;
  final String businessAddress;
  final String? logo;
  final bool isEmailVerified;

  SellerModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.businessName,
    required this.businessAddress,
    this.logo,
    required this.isEmailVerified,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      email: json['email'] ?? '',
      businessName: json['business_name'] ?? '',
      businessAddress: json['business_address'] ?? '',
      logo: json['logo'],
      isEmailVerified: json['is_email_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'email': email,
      'business_name': businessName,
      'business_address': businessAddress,
      'logo': logo,
      'is_email_verified': isEmailVerified,
    };
  }
}
