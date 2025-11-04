// lib/presentation/pages/product/enhanced_product_details_content.dart
import 'package:anu_app/config/theme.dart';
import 'package:anu_app/presentation/pages/product/widgets/trust_badges_widget.dart';
import 'package:anu_app/presentation/widgets/reviews/average_rating_widget.dart';
import 'package:anu_app/presentation/widgets/reviews/review_form.dart';
import 'package:anu_app/presentation/widgets/reviews/review_list.dart';
import 'package:anu_app/providers/product_provider.dart';
import 'package:anu_app/providers/review_provider.dart';
import 'package:anu_app/providers/wishlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    print(widget.product.isWishlisted);
    _initializeVariants();
    _loadSimilarProducts();
  }

  void _initializeVariants() {
    if (widget.variantData != null && widget.variantData!.colors.isNotEmpty) {
      _selectedColor = widget.variantData!.colors.first.colorValue;
      _updateCurrentImages();
    } else {
      _currentImages = widget.product.images;
    }
  }

  Future<void> _loadSimilarProducts() async {
    if (widget.product.category.isNotEmpty) {
      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);
      await productProvider.loadProductsByCategory(widget.product.category);
    }
  }

  void _updateCurrentImages() {
    if (_selectedColor != null) {
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
    print("this is for test");
    print(widget.variantData);
    if (widget.variantData == null || widget.variantData!.colors.isEmpty)
      return true;
    return _selectedColor != null &&
        _selectedSize != null &&
        _selectedVariantId != null;
  }

  void _showReviewForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewForm(
          productSlug: widget.product.slug,
          onSuccess: () {
            // Refresh reviews after successful submission
            context
                .read<ReviewProvider>()
                .getProductReviews(widget.product.slug);
          },
        ),
      ),
    );
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    double? selectedPrice;
    if (_selectedPrice != null) {
      selectedPrice = _selectedPrice;
    } else {
      selectedPrice = double.tryParse(widget.product.salePrice) ??
          double.tryParse(widget.product.regularPrice) ??
          0.0;
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
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  _getCurrentPrice(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
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

  Widget _buildHtmlDescription() {
    if (widget.product.description.isEmpty) {
      return const Text(
        'No description available for this product.',
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Check if content is HTML by looking for HTML tags
    final bool isHtml = widget.product.description.contains('<') &&
        widget.product.description.contains('>');

    if (!isHtml) {
      // If it's plain text, display normally
      return Text(
        widget.product.description,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
        ),
      );
    }

    // For HTML content, use flutter_html package
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isDescriptionExpanded ? null : 200,
          child: SingleChildScrollView(
            physics: _isDescriptionExpanded
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Html(
              data: widget.product.description,
              style: {
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontSize: FontSize(14),
                  lineHeight: const LineHeight(1.6),
                  color: Colors.black87,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 12),
                  fontSize: FontSize(14),
                  lineHeight: const LineHeight(1.6),
                ),
                "h1, h2, h3, h4, h5, h6": Style(
                  margin: Margins.only(top: 16, bottom: 8),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                "h1": Style(fontSize: FontSize(22)),
                "h2": Style(fontSize: FontSize(20)),
                "h3": Style(fontSize: FontSize(18)),
                "h4": Style(fontSize: FontSize(16)),
                "ul, ol": Style(
                  margin: Margins.only(left: 16, bottom: 12),
                ),
                "li": Style(
                  margin: Margins.only(bottom: 4),
                ),
                "strong, b": Style(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                "em, i": Style(
                  fontStyle: FontStyle.italic,
                ),
                "a": Style(
                  color: AppTheme.primaryColor,
                  textDecoration: TextDecoration.underline,
                ),
                "blockquote": Style(
                  margin: Margins.symmetric(vertical: 12),
                  padding: HtmlPaddings.only(left: 16),
                  border: Border(
                    left: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 4,
                    ),
                  ),
                  backgroundColor: Colors.grey.shade50,
                ),
                "code": Style(
                  backgroundColor: Colors.grey.shade100,
                  padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                  fontFamily: 'monospace',
                  fontSize: FontSize(13),
                ),
                "pre": Style(
                  backgroundColor: Colors.grey.shade100,
                  padding: HtmlPaddings.all(12),
                  margin: Margins.symmetric(vertical: 8),
                  display: Display.block,
                ),
                "table": Style(
                  border: Border.all(color: Colors.grey.shade300),
                  margin: Margins.symmetric(vertical: 12),
                ),
                "th, td": Style(
                  border: Border.all(color: Colors.grey.shade300),
                  padding: HtmlPaddings.all(8),
                ),
                "th": Style(
                  backgroundColor: Colors.grey.shade100,
                  fontWeight: FontWeight.bold,
                ),
              },
              onLinkTap: (url, attributes, element) async {
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                }
              },
              extensions: [
                TagExtension(
                  tagsToExtend: {"img"},
                  builder: (extensionContext) {
                    final src = extensionContext.attributes['src'];
                    if (src != null) {
                      return GestureDetector(
                        onTap: () {
                          // Show image in fullscreen dialog
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.black,
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        src,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.error,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              src,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 200,
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),

        // Show/Hide button if content is long
        if (widget.product.description.length > 500) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isDescriptionExpanded ? 'Show Less' : 'Show More',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isDescriptionExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // NEW: Build Similar Products Section
  Widget _buildSimilarProductsSection() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Filter out the current product from similar products
        final similarProducts = productProvider.categoryProducts
            .where((product) => product.id != widget.product.id)
            .take(10) // Limit to 10 products
            .toList();

        if (similarProducts.isEmpty && !productProvider.isLoadingCategory) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'You May Like This',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (similarProducts.length > 4)
                    TextButton(
                      onPressed: () {
                        // Navigate to category products page
                        final categoryName = widget.breadcrumbs.isNotEmpty
                            ? widget.breadcrumbs.last.name
                            : 'Products';
                        context.push(
                            '/products?type=category&title=$categoryName&category=${widget.product.category}');
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loading state
            if (productProvider.isLoadingCategory)
              Container(
                height: 280,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              )
            else
              // Horizontal scrollable list of similar products
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: similarProducts.length,
                  itemBuilder: (context, index) {
                    final product = similarProducts[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildSimilarProductCard(product),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // NEW: Build Similar Product Card
  Widget _buildSimilarProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        context.push('/product/${product.slug}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[100],
                      child: product.primaryImageUrl.isNotEmpty
                          ? Image.network(
                              product.primaryImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, error, _) => Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.image,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                    ),
                  ),

                  // Discount badge
                  if (product.discountPercentage.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4947),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.discountPercentage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Wishlist button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlistProvider, child) {
                        final isWishlisted = wishlistProvider
                            .isInWishlist(product.id.toString());
                        return GestureDetector(
                          onTap: () async {
                            await Provider.of<ProductProvider>(context,
                                    listen: false)
                                .toggleWishlist(product, context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isWishlisted
                                  ? const Color(0xFFFF4947)
                                  : Colors.grey,
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Price section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                          child: Text(
                            product.formattedSalePrice,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (product.discountPercentage.isNotEmpty)
                          Text(
                            product.formattedRegularPrice,
                            style: TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                          Consumer<WishlistProvider>(
                            builder: (context, wishlistProvider, child) {
                              final isWishlisted = wishlistProvider
                                  .isInWishlist(widget.product.id.toString());

                              return IconButton(
                                icon: Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isWishlisted
                                      ? const Color(0xFFFF4947)
                                      : Colors.grey,
                                ),
                                onPressed: () async {
                                  await Provider.of<ProductProvider>(context,
                                          listen: false)
                                      .toggleWishlist(widget.product, context);
                                },
                                tooltip: isWishlisted
                                    ? 'Remove from Wishlist'
                                    : 'Add to Wishlist',
                              );
                            },
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

                      // Average Rating Section
                      AverageRatingWidget(productSlug: widget.product.slug),

                      const SizedBox(height: 20),

                      // Trust Badge Section
                      const TrustBadgesWidget(),

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

                      // Description section with HTML support
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildHtmlDescription(),

                      const SizedBox(height: 32),

                      // Reviews Section
                      const Text(
                        'Reviews & Ratings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Write Review Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showReviewForm(context);
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Write a Review'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            side: BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      // Reviews List
                      ReviewList(productSlug: widget.product.slug),

                      const SizedBox(height: 32),

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
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: widget.product.attributes
                                .where((attr) => attr.isVisible)
                                .map((attr) => Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 0.5,
                                          ),
                                        ),
                                      ),
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
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),

                // Similar Products Section - Added here
                _buildSimilarProductsSection(),

                const SizedBox(height: 100), // Space for bottom buttons
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
                      child: _isAddToCartEnabled()
                          ? InkWell(
                              onTap: _addToCart,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.primaryColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add to Cart',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    const SizedBox(width: 12),

                    // Buy Now button
                    Expanded(
                      child: _isAddToCartEnabled()
                          ? InkWell(
                              onTap: _buyNow,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.flash_on, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Buy Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flash_on, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    'Buy Now',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
