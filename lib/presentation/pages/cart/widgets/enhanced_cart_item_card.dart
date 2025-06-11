// lib/presentation/pages/cart/widgets/enhanced_cart_item_card.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../core/models/mobile_variant_model.dart';
import '../../../../api/services/cart_image_service.dart';
import '../../../../api/services/product_service.dart';
import '../../../../config/theme.dart';

class EnhancedCartItemCard extends StatefulWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const EnhancedCartItemCard({
    Key? key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<EnhancedCartItemCard> createState() => _EnhancedCartItemCardState();
}

class _EnhancedCartItemCardState extends State<EnhancedCartItemCard> {
  final CartImageService _imageService = CartImageService();
  final ProductService _productService = ProductService();
  String? _variantImageUrl;
  bool _isLoadingImage = true;
  bool _isLoadingVariantInfo = true;
  String? _selectedSize;
  String? _selectedColor;
  String? _selectedColorDisplay;

  @override
  void initState() {
    super.initState();
    _loadVariantImage();
    _loadVariantInfo();
  }

  Future<void> _loadVariantImage() async {
    if (widget.item.productInfo?.slug != null) {
      final imageUrl = await _imageService.getCartItemImageUrl(
        widget.item.productInfo!.slug,
        widget.item.variantId,
      );

      if (mounted) {
        setState(() {
          _variantImageUrl = imageUrl;
          _isLoadingImage = false;
        });
      }
    } else {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  Future<void> _loadVariantInfo() async {
    if (widget.item.productInfo?.slug != null &&
        widget.item.variantId != null) {
      try {
        final result = await _productService.getMobileVariantSelector(
          widget.item.productInfo!.slug,
        );

        if (result['success'] && mounted) {
          final variantData = result['data'] as MobileVariantSelector;
          _extractVariantDetails(variantData);
        }
      } catch (e) {
        print('Error loading variant info: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingVariantInfo = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingVariantInfo = false;
      });
    }
  }

  void _extractVariantDetails(MobileVariantSelector variantData) {
    final variantIdInt = int.tryParse(widget.item.variantId ?? '');
    if (variantIdInt == null) return;

    // Find the matching variant by checking all color and size combinations
    // Using your existing model structure with variantId
    for (final color in variantData.colors) {
      for (final size in color.availableSizes) {
        // Check if this size option matches our variant ID
        if (size.variantId == variantIdInt) {
          setState(() {
            _selectedColor = color.colorValue;
            _selectedColorDisplay = color.colorDisplay;
            _selectedSize = size.sizeValue;
          });
          return;
        }
      }
    }
  }

  // Remove the helper method since we're using the existing variantId property

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final isTablet = screenWidth >= 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal:
            AppTheme.getResponsiveHorizontalPadding(context).horizontal / 2,
        vertical: 6,
      ),
      child: Card(
        elevation: AppTheme.getCardElevation(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
        ),
        child: InkWell(
          onTap: () {
            if (widget.item.productInfo?.slug != null) {
              context.go('/product/${widget.item.productInfo!.slug}');
            }
          },
          borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
          child: Padding(
            padding: AppTheme.getResponsiveCardPadding(context),
            child: isTablet
                ? _buildTabletLayout(isCompact)
                : _buildMobileLayout(isCompact),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isCompact) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(isCompact),
            SizedBox(width: isCompact ? 12 : 16),
            Expanded(
              child: _buildProductDetails(isCompact),
            ),
          ],
        ),
        if (!isCompact) const SizedBox(height: 12),
        _buildQuantityAndPrice(isCompact),
      ],
    );
  }

  Widget _buildTabletLayout(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductImage(isCompact),
        SizedBox(width: isCompact ? 12 : 20),
        Expanded(
          flex: 3,
          child: _buildProductDetails(isCompact),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildQuantityAndPrice(isCompact, isTablet: true),
        ),
      ],
    );
  }

  Widget _buildProductImage(bool isCompact) {
    final size =
        isCompact ? 80.0 : (AppTheme.isTablet(context) ? 120.0 : 100.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.getCardRadius(context)),
        child: _isLoadingImage ? _buildImageSkeleton() : _buildImageContent(),
      ),
    );
  }

  Widget _buildImageSkeleton() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final imageUrl = _variantImageUrl ?? widget.item.imageUrl;

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageSkeleton();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildSellerInfo(bool isCompact) {
    // Only show seller info if we have the data
    if (widget.item.brandName.isEmpty &&
        widget.item.sellerUsername.isEmpty &&
        widget.item.sellerBusinessName.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: isCompact ? 6 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BRAND NAME DISPLAY (from API field: brand_name)
          if (widget.item.brandName.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: isCompact ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_offer,
                    size: isCompact ? 12 : 14,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    widget.item
                        .brandName, // Shows: "Kart Avenue", "Individual Designs"
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // SELLER USERNAME DISPLAY (from API field: seller_username)
          if (widget.item.sellerUsername.isNotEmpty) ...[
            SizedBox(height: isCompact ? 4 : 6),
            Row(
              children: [
                Icon(
                  Icons.store,
                  size: isCompact ? 11 : 12,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Sold by ${widget.item.sellerUsername}', // Shows: "Sold by Anugami pvt ltd", "Sold by Parveen Daga"
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // SELLER BUSINESS NAME DISPLAY (from API field: seller_business_name)
          if (widget.item.sellerBusinessName.isNotEmpty &&
              widget.item.sellerBusinessName != widget.item.sellerUsername) ...[
            SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: isCompact ? 11 : 12,
                  color: Colors.grey.shade500,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.item
                        .sellerBusinessName, // Shows: "ANUGAMI24 TECHNOLOGIES PRIVATE LIMITED", "ID EXPORTS PRIVATE LIMITED"
                    style: TextStyle(
                      fontSize: isCompact ? 9 : 10,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildProductDetails(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.item.name,
                style: TextStyle(
                  fontSize: isCompact ? 14 : AppTheme.getTitleFontSize(context),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: Icon(
                Icons.close,
                size: AppTheme.getSmallIconSize(context),
                color: Colors.grey.shade600,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ),

        _buildSellerInfo(isCompact),

        // Variant Information Section
        if (widget.item.variantId != null) ...[
          const SizedBox(height: 8),
          _buildVariantInfo(isCompact),
        ],

        // Discount and pricing info
        if (widget.item.hasDiscount) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${widget.item.regularPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(((widget.item.regularPrice - widget.item.salePrice) / widget.item.regularPrice) * 100).toInt()}% OFF',
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 12,
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 8),

        // Stock status
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.item.isAvailable
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.item.isAvailable ? 'In Stock' : 'Out of Stock',
              style: TextStyle(
                fontSize: isCompact ? 12 : 14,
                color: widget.item.isAvailable
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariantInfo(bool isCompact) {
    if (_isLoadingVariantInfo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading variant...',
              style: TextStyle(
                fontSize: isCompact ? 10 : 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    List<Widget> variantChips = [];

    // Color chip with both color preview and name
    if (_selectedColor != null && _selectedColorDisplay != null) {
      variantChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color preview circle
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _parseColor(_selectedColor!),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                // Add a small white dot for very dark colors for better visibility
                child: _parseColor(_selectedColor!).computeLuminance() < 0.3
                    ? Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              // Color name
              Text(
                _selectedColorDisplay!,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Size chip with enhanced styling
    if (_selectedSize != null) {
      variantChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.secondaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.straighten,
                size: 14,
                color: AppTheme.secondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                _selectedSize!,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If no variant info is available, show variant ID with better styling
    if (variantChips.isEmpty && widget.item.variantId != null) {
      variantChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tag,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                'ID: ${widget.item.variantId}',
                style: TextStyle(
                  fontSize: isCompact ? 10 : 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: variantChips,
    );
  }

  Color _parseColor(String colorValue) {
    try {
      // Handle hex color codes
      if (colorValue.startsWith('#')) {
        String cleanColor = colorValue.replaceAll('#', '');
        if (cleanColor.length == 6) {
          return Color(int.parse('FF$cleanColor', radix: 16));
        }
      }

      // Handle RGB format like "rgb(255,0,0)"
      if (colorValue.toLowerCase().startsWith('rgb(')) {
        final rgbValues = colorValue
            .replaceAll('rgb(', '')
            .replaceAll(')', '')
            .split(',')
            .map((e) => int.tryParse(e.trim()) ?? 0)
            .toList();
        if (rgbValues.length == 3) {
          return Color.fromRGBO(rgbValues[0], rgbValues[1], rgbValues[2], 1.0);
        }
      }

      // Handle named colors
      switch (colorValue.toLowerCase().trim()) {
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.yellow;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'orange':
          return Colors.orange;
        case 'brown':
          return Colors.brown;
        case 'gray':
        case 'grey':
          return Colors.grey;
        case 'navy':
          return const Color(0xFF001f3f);
        case 'teal':
          return Colors.teal;
        case 'maroon':
          return const Color(0xFF800000);
        case 'lime':
          return Colors.lime;
        case 'cyan':
          return Colors.cyan;
        case 'indigo':
          return Colors.indigo;
        case 'amber':
          return Colors.amber;
        case 'khaki':
          return const Color(0xFFF0E68C);
        case 'olive':
          return const Color(0xFF808000);
        case 'silver':
          return const Color(0xFFC0C0C0);
        case 'gold':
          return const Color(0xFFFFD700);
        case 'beige':
          return const Color(0xFFF5F5DC);
        case 'cream':
          return const Color(0xFFFFFDD0);
        case 'ivory':
          return const Color(0xFFFFFFF0);
        case 'coral':
          return const Color(0xFFFF7F50);
        case 'salmon':
          return const Color(0xFFFA8072);
        case 'turquoise':
          return const Color(0xFF40E0D0);
        case 'lavender':
          return const Color(0xFFE6E6FA);
        case 'mint':
          return const Color(0xFF98FB98);
        case 'rose':
          return const Color(0xFFFFE4E1);
        default:
          // Try to parse as a hex color without #
          if (colorValue.length == 6) {
            try {
              return Color(int.parse('FF$colorValue', radix: 16));
            } catch (e) {
              // Fall through to default
            }
          }
          return Colors.grey.shade400;
      }
    } catch (e) {
      // Fall back to a default color
      return Colors.grey.shade400;
    }
  }

  Widget _buildQuantityAndPrice(bool isCompact, {bool isTablet = false}) {
    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPriceDisplay(isCompact),
          const SizedBox(height: 12),
          _buildQuantityControls(isCompact),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuantityControls(isCompact),
          _buildPriceDisplay(isCompact),
        ],
      );
    }
  }

  Widget _buildQuantityControls(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(AppTheme.getButtonRadius(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onPressed: widget.item.quantity > 1 ? widget.onDecrement : null,
            isCompact: isCompact,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 8 : 12,
            ),
            child: Text(
              '${widget.item.quantity}',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onPressed: widget.onIncrement,
            isCompact: isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isCompact,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.getButtonRadius(context)),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        child: Icon(
          icon,
          size: AppTheme.getSmallIconSize(context),
          color:
              onPressed != null ? AppTheme.primaryColor : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildPriceDisplay(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${widget.item.totalPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        if (widget.item.quantity > 1)
          Text(
            '₹${widget.item.price.toStringAsFixed(0)} each',
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }
}
