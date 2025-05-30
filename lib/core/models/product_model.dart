// lib/core/models/product_model.dart
class ProductModel {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String shortDescription;
  final String category;
  final BrandModel brand;
  final String regularPrice;
  final String salePrice;
  final String costPrice;
  final int stockQuantity;
  final bool isActive;
  final bool isFeatured;
  final List<ImageModel> images;
  final List<VideoModel> videos;
  final List<AttributeModel> attributes;
  final List<ReviewModel> reviews;
  final List<VariantModel> variants;
  final Map<String, List<ImageModel>> colorImages;
  final List<ColorOption> availableColors;
  final Map<String, List<SizeOption>> availableSizes;
  final String createdAt;
  final String updatedAt;
  final SellerModel? sellerInfo;
  final bool isWishlisted;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.shortDescription,
    required this.category,
    required this.brand,
    required this.regularPrice,
    required this.salePrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.isActive,
    required this.isFeatured,
    required this.images,
    required this.videos,
    required this.attributes,
    required this.reviews,
    required this.variants,
    required this.colorImages,
    required this.availableColors,
    required this.availableSizes,
    required this.createdAt,
    required this.updatedAt,
    this.sellerInfo,
    this.isWishlisted = false,
  });

  // Create a copy of the product with modified properties
  ProductModel copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? shortDescription,
    String? category,
    BrandModel? brand,
    String? regularPrice,
    String? salePrice,
    String? costPrice,
    int? stockQuantity,
    bool? isActive,
    bool? isFeatured,
    List<ImageModel>? images,
    List<VideoModel>? videos,
    List<AttributeModel>? attributes,
    List<ReviewModel>? reviews,
    List<VariantModel>? variants,
    Map<String, List<ImageModel>>? colorImages,
    List<ColorOption>? availableColors,
    Map<String, List<SizeOption>>? availableSizes,
    String? createdAt,
    String? updatedAt,
    SellerModel? sellerInfo,
    bool? isWishlisted,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      regularPrice: regularPrice ?? this.regularPrice,
      salePrice: salePrice ?? this.salePrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      images: images ?? this.images,
      videos: videos ?? this.videos,
      attributes: attributes ?? this.attributes,
      reviews: reviews ?? this.reviews,
      variants: variants ?? this.variants,
      colorImages: colorImages ?? this.colorImages,
      availableColors: availableColors ?? this.availableColors,
      availableSizes: availableSizes ?? this.availableSizes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerInfo: sellerInfo ?? this.sellerInfo,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }

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

  Map<String, dynamic> toCardMap() {
    return {
      'id': id.toString(),
      'name': name,
      'price': formattedSalePrice,
      'image': primaryImageUrl,
      'discount': discountPercentage,
      'inStock': stockQuantity > 0,
    };
  }

  // Get images for selected color
  List<ImageModel> getImagesForColor(String? selectedColor) {
    if (selectedColor != null && colorImages.containsKey(selectedColor)) {
      return colorImages[selectedColor]!;
    }
    return images;
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

  // Enhanced fromJson with variants support
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse images
      List<ImageModel> imagesList = [];
      if (json['images'] != null && json['images'] is List) {
        imagesList = (json['images'] as List)
            .map((img) => ImageModel.fromJson(img))
            .toList();
      }

      // Parse videos
      List<VideoModel> videosList = [];
      if (json['videos'] != null && json['videos'] is List) {
        videosList = (json['videos'] as List)
            .map((video) => VideoModel.fromJson(video))
            .toList();
      }

      // Parse attributes
      List<AttributeModel> attributesList = [];
      if (json['attributes'] != null && json['attributes'] is List) {
        attributesList = (json['attributes'] as List)
            .map((attr) => AttributeModel.fromJson(attr))
            .toList();
      }

      // Parse reviews
      List<ReviewModel> reviewsList = [];
      if (json['reviews'] != null && json['reviews'] is List) {
        reviewsList = (json['reviews'] as List)
            .map((review) => ReviewModel.fromJson(review))
            .toList();
      }

      // Parse variants
      List<VariantModel> variantsList = [];
      if (json['variants'] != null && json['variants'] is List) {
        variantsList = (json['variants'] as List)
            .map((variant) => VariantModel.fromJson(variant))
            .toList();
      }

      // Parse color images
      Map<String, List<ImageModel>> colorImagesMap = {};
      if (json['color_images'] != null && json['color_images'] is Map) {
        final colorImagesJson = json['color_images'] as Map<String, dynamic>;
        colorImagesJson.forEach((color, images) {
          if (images is List) {
            colorImagesMap[color] =
                images.map((img) => ImageModel.fromJson(img)).toList();
          }
        });
      }

      // Parse available colors
      List<ColorOption> availableColorsList = [];
      if (json['available_colors'] != null &&
          json['available_colors'] is List) {
        availableColorsList = (json['available_colors'] as List)
            .map((color) => ColorOption.fromJson(color))
            .toList();
      }

      // Parse available sizes
      Map<String, List<SizeOption>> availableSizesMap = {};
      if (json['available_sizes'] != null && json['available_sizes'] is Map) {
        final sizesJson = json['available_sizes'] as Map<String, dynamic>;
        sizesJson.forEach((color, sizes) {
          if (sizes is List) {
            availableSizesMap[color] =
                sizes.map((size) => SizeOption.fromJson(size)).toList();
          }
        });
      }

      // Parse brand
      BrandModel brandModel = BrandModel.empty();
      if (json['brand'] != null) {
        if (json['brand'] is Map<String, dynamic>) {
          brandModel = BrandModel.fromJson(json['brand']);
        } else if (json['brand'] is int) {
          brandModel = BrandModel(
            id: json['brand'],
            name: '',
            slug: '',
            description: '',
            logo: '',
            isActive: true,
            createdAt: '',
            updatedAt: '',
          );
        }
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
        shortDescription: json['short_description'] ?? '',
        category: json['category']?.toString() ?? '',
        brand: brandModel,
        regularPrice: (json['regular_price'] ?? '0.00').toString(),
        salePrice: (json['sale_price'] ?? '0.00').toString(),
        costPrice: (json['cost_price'] ?? '0.00').toString(),
        stockQuantity: json['stock_quantity'] ?? 0,
        isActive: json['is_active'] ?? false,
        isFeatured: json['is_featured'] ?? false,
        images: imagesList,
        videos: videosList,
        attributes: attributesList,
        reviews: reviewsList,
        variants: variantsList,
        colorImages: colorImagesMap,
        availableColors: availableColorsList,
        availableSizes: availableSizesMap,
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        sellerInfo: sellerModel,
        isWishlisted: json['is_wishlisted'] ?? false,
      );
    } catch (e, stackTrace) {
      print('Error creating ProductModel from JSON: $e');
      print('Stack trace: $stackTrace');
      return ProductModel.empty();
    }
  }

  // Create an empty product model for placeholders
  factory ProductModel.empty() {
    return ProductModel(
      id: 0,
      name: '',
      slug: '',
      description: '',
      shortDescription: '',
      category: '',
      brand: BrandModel.empty(),
      regularPrice: '0.00',
      salePrice: '0.00',
      costPrice: '0.00',
      stockQuantity: 0,
      isActive: false,
      isFeatured: false,
      images: [],
      videos: [],
      attributes: [],
      reviews: [],
      variants: [],
      colorImages: {},
      availableColors: [],
      availableSizes: {},
      createdAt: '',
      updatedAt: '',
    );
  }
}

// Additional Models for Variants
class VariantModel {
  final int id;
  final String sku;
  final int stockQuantity;
  final double price;
  final bool isActive;
  final List<VariantAttributeModel> attributes;
  final String createdAt;
  final String updatedAt;

  VariantModel({
    required this.id,
    required this.sku,
    required this.stockQuantity,
    required this.price,
    required this.isActive,
    required this.attributes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: json['id'] ?? 0,
      sku: json['sku'] ?? '',
      stockQuantity: json['stock_quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? false,
      attributes: (json['attributes'] as List?)
              ?.map((attr) => VariantAttributeModel.fromJson(attr))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class VariantAttributeModel {
  final int id;
  final String attributeType;
  final String value;
  final String displayValue;

  VariantAttributeModel({
    required this.id,
    required this.attributeType,
    required this.value,
    required this.displayValue,
  });

  factory VariantAttributeModel.fromJson(Map<String, dynamic> json) {
    return VariantAttributeModel(
      id: json['id'] ?? 0,
      attributeType: json['attribute_type'] ?? '',
      value: json['value'] ?? '',
      displayValue: json['display_value'] ?? '',
    );
  }
}

class AttributeModel {
  final int id;
  final int product;
  final String attributeType;
  final String name;
  final String value;
  final String displayValue;
  final String type;
  final bool isVisible;
  final bool isVariation;
  final bool isSearchable;
  final int sortOrder;
  final List<List<String>> availableValues;

  AttributeModel({
    required this.id,
    required this.product,
    required this.attributeType,
    required this.name,
    required this.value,
    required this.displayValue,
    required this.type,
    required this.isVisible,
    required this.isVariation,
    required this.isSearchable,
    required this.sortOrder,
    required this.availableValues,
  });

  factory AttributeModel.fromJson(Map<String, dynamic> json) {
    return AttributeModel(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      attributeType: json['attribute_type'] ?? '',
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      displayValue: json['display_value'] ?? '',
      type: json['type'] ?? '',
      isVisible: json['is_visible'] ?? false,
      isVariation: json['is_variation'] ?? false,
      isSearchable: json['is_searchable'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      availableValues: (json['available_values'] as List?)
              ?.map((item) => List<String>.from(item))
              .toList() ??
          [],
    );
  }
}

class VideoModel {
  final int id;
  final int product;
  final String videoUrl;
  final String title;
  final String description;
  final int sortOrder;
  final String createdAt;

  VideoModel({
    required this.id,
    required this.product,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? 0,
      product: json['product'] ?? 0,
      videoUrl: json['video_url'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ReviewModel {
  final int id;
  final int rating;
  final String comment;
  final String customerName;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.customerName,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      customerName: json['customer_name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ColorOption {
  final String value;
  final String displayValue;
  final bool hasImage;

  ColorOption({
    required this.value,
    required this.displayValue,
    required this.hasImage,
  });

  factory ColorOption.fromJson(Map<String, dynamic> json) {
    return ColorOption(
      value: json['value'] ?? '',
      displayValue: json['display_value'] ?? '',
      hasImage: json['has_image'] ?? false,
    );
  }
}

class SizeOption {
  final String sizeValue;
  final String sizeDisplay;
  final int stock;
  final int variantId;
  final double price;

  SizeOption({
    required this.sizeValue,
    required this.sizeDisplay,
    required this.stock,
    required this.variantId,
    required this.price,
  });

  factory SizeOption.fromJson(Map<String, dynamic> json) {
    return SizeOption(
      sizeValue: json['size_value'] ?? '',
      sizeDisplay: json['size_display'] ?? '',
      stock: json['stock'] ?? 0,
      variantId: json['variant_id'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  bool get inStock => stock > 0;
}

// Update ImageModel to include color_attribute
class ImageModel {
  final int id;
  final int product;
  final String imageUrl;
  final String altText;
  final bool isPrimary;
  final int sortOrder;
  final String createdAt;
  final String storagePath;
  final String? colorAttribute;

  ImageModel({
    required this.id,
    required this.product,
    required this.imageUrl,
    required this.altText,
    required this.isPrimary,
    required this.sortOrder,
    required this.createdAt,
    required this.storagePath,
    this.colorAttribute,
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
      colorAttribute: json['color_attribute'],
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
      'color_attribute': colorAttribute,
    };
  }
}

// Keep existing BrandModel and SellerModel classes as they are...

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
