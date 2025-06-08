// lib/presentation/pages/product/enhanced_product_details_content.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/breadcrumb_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/mobile_variant_model.dart';
import '../../../providers/cart_provider.dart';
import 'widgets/breadcrumb_widget.dart';
import 'widgets/product_image_slider.dart';
import 'widgets/variant_selector_widget.dart';

class EnhancedProductDetailsContent extends StatefulWidget {
  final ProductModel product;
  final MobileVariantSelector? variantData;
  final List<BreadcrumbModel> breadcrumbs;
  final VoidCallback onWishlistToggle;

  const EnhancedProductDetailsContent({
    super.key,
    required this.product,
    this.variantData,
    this.breadcrumbs = const [],
    required this.onWishlistToggle,
  });

  @override
  State<EnhancedProductDetailsContent> createState() =>
      _EnhancedProductDetailsContentState();
}

class _EnhancedProductDetailsContentState
    extends State<EnhancedProductDetailsContent> {
  String? _selectedColor;
  String? _selectedSize;
  int? _selectedVariantId;
  double? _selectedPrice;
  List<ImageModel> _currentImages = [];

  @override
  void initState() {
    super.initState();
    _initializeVariants();
  }

  void _initializeVariants() {
    if (widget.variantData != null && widget.variantData!.colors.isNotEmpty) {
      _selectedColor = widget.variantData!.colors.first.colorValue;
      _updateCurrentImages();
    } else {
      _currentImages = widget.product.images;
    }
  }

  void _updateCurrentImages() {
    if (_selectedColor != null) {
      // Use color-specific images if available
      final colorImages = widget.product.getImagesForColor(_selectedColor);
      setState(() {
        _currentImages = colorImages;
      });
    } else {
      setState(() {
        _currentImages = widget.product.images;
      });
    }
  }

  void _onVariantChanged(String? selectedColor, String? selectedSize,
      int? variantId, double? price) {
    setState(() {
      _selectedColor = selectedColor;
      _selectedSize = selectedSize;
      _selectedVariantId = variantId;
      _selectedPrice = price;
    });
    _updateCurrentImages();
  }

  String _getCurrentPrice() {
    if (_selectedPrice != null) {
      return '₹${_selectedPrice!.toStringAsFixed(2)}';
    }
    return widget.product.formattedSalePrice;
  }

  bool _isAddToCartEnabled() {
    if (widget.variantData == null) return true;
    return _selectedColor != null &&
        _selectedSize != null &&
        _selectedVariantId != null;
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // Get the selected variant price if available
    double? selectedPrice;
    if (_selectedPrice != null) {
      selectedPrice = _selectedPrice;
    } else {
      selectedPrice = double.tryParse(widget.product.salePrice) ?? 
                     double.tryParse(widget.product.regularPrice) ?? 0.0;
    }
  
    cartProvider.addItem(
      widget.product,
      quantity: 1,
      variantId: _selectedVariantId?.toString(),
      price: selectedPrice,
    );
  
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            context.push('/cart');
          },
        ),
      ),
    );
  }

  void _buyNow() {
    _addToCart();
    context.push('/cart');
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getCurrentPrice(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF7A2E),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.product.discountPercentage.isNotEmpty) ...[
                Text(
                  widget.product.formattedRegularPrice,
                  style: TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4947),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.product.discountPercentage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (widget.variantData != null && _selectedColor == null) ...[
            const SizedBox(height: 8),
            Text(
              'Price Range: ${widget.variantData!.getPriceRange()}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockInfo() {
    int stockQuantity = widget.product.stockQuantity;

    // If a specific variant is selected, use its stock
    if (_selectedColor != null &&
        _selectedSize != null &&
        widget.variantData != null) {
      try {
        final colorOption = widget.variantData!.colors
            .firstWhere((c) => c.colorValue == _selectedColor);
        final sizeOption = colorOption.availableSizes
            .firstWhere((s) => s.sizeValue == _selectedSize);
        stockQuantity = sizeOption.stock;
      } catch (e) {
        // Use default stock if variant not found
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stockQuantity > 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              stockQuantity > 0 ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            stockQuantity > 0 ? Icons.check_circle : Icons.error,
            size: 18,
            color: stockQuantity > 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            stockQuantity > 0
                ? stockQuantity <= 5
                    ? 'Only $stockQuantity left in stock'
                    : 'In Stock'
                : 'Out of Stock',
            style: TextStyle(
              color: stockQuantity > 0
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs
                if (widget.breadcrumbs.isNotEmpty)
                  BreadcrumbWidget(
                    breadcrumbs: widget.breadcrumbs,
                    onTap: (slug) {
                      if (slug.isEmpty) {
                        context.go('/home');
                      } else {
                        final categoryName = widget.breadcrumbs
                            .firstWhere((b) => b.slug == slug,
                                orElse: () => BreadcrumbModel(
                                    id: '', name: 'Category', slug: slug))
                            .name;
                        context.go(
                            '/products?type=category&title=$categoryName&category=$slug');
                      }
                    },
                  ),

                // Image slider with current images
                ProductImageSlider(images: _currentImages),

                // Product info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product title and wishlist button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              widget.product.isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.product.isWishlisted
                                  ? const Color(0xFFFF4947)
                                  : Colors.grey,
                            ),
                            onPressed: widget.onWishlistToggle,
                          ),
                        ],
                      ),

                      // Seller name if available
                      if (widget.product.sellerInfo != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Sold by: ${widget.product.sellerInfo!.userName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),

                      // Price section
                      _buildPriceSection(),

                      const SizedBox(height: 16),

                      // Stock info
                      _buildStockInfo(),

                      const SizedBox(height: 20),

                      // Variant selector
                      if (widget.variantData != null)
                        VariantSelectorWidget(
                          variantData: widget.variantData!,
                          onVariantChanged: _onVariantChanged,
                          initialColor: _selectedColor,
                          initialSize: _selectedSize,
                        ),

                      if (widget.variantData != null)
                        const SizedBox(height: 20),

                      // Description section
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description.isNotEmpty
                            ? widget.product.description
                            : 'No description available for this product.',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Brand info
                      if (widget.product.brand.name.isNotEmpty) ...[
                        const Text(
                          'Brand',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              if (widget.product.brand.logo.isNotEmpty)
                                Image.network(
                                  widget.product.brand.logo,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.business, size: 40),
                                ),
                              if (widget.product.brand.logo.isNotEmpty)
                                const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product.brand.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (widget
                                        .product.brand.description.isNotEmpty)
                                      Text(
                                        widget.product.brand.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Product attributes
                      if (widget.product.attributes.isNotEmpty) ...[
                        const Text(
                          'Specifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.product.attributes
                            .where((attr) => attr.isVisible)
                            .map((attr) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          '${attr.displayValue}:',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          attr.value,
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 100), // Space for bottom buttons
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom action buttons
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Variant selection status
                if (widget.variantData != null && !_isAddToCartEnabled())
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please select ${_selectedColor == null ? 'color' : ''}${_selectedColor == null && _selectedSize == null ? ' and ' : ''}${_selectedSize == null ? 'size' : ''} to continue',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action buttons
                Row(
                  children: [
                    // Add to Cart button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isAddToCartEnabled() ? _addToCart : null,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Add to Cart'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isAddToCartEnabled()
                              ? const Color(0xFFFF7A2E)
                              : Colors.grey,
                          side: BorderSide(
                            color: _isAddToCartEnabled()
                                ? const Color(0xFFFF7A2E)
                                : Colors.grey.shade300,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Buy Now button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAddToCartEnabled() ? _buyNow : null,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Buy Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAddToCartEnabled()
                              ? const Color(0xFFFF7A2E)
                              : Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: _isAddToCartEnabled() ? 2 : 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
