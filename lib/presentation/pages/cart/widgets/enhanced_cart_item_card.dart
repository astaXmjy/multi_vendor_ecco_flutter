import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/cart_item_model.dart';
import '../../../../api/services/cart_image_service.dart';
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
  String? _variantImageUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadVariantImage();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (widget.item.productInfo?.slug != null) {
            context.go('/product/${widget.item.productInfo!.slug}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
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
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(bool isCompact) {
    final size = isCompact ? 80.0 : 100.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: Icon(
                Icons.close,
                size: isCompact ? 20 : 24,
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
        if (widget.item.hasDiscount) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '₹${widget.item.regularPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(((widget.item.regularPrice - widget.item.salePrice) / widget.item.regularPrice) * 100).toInt()}% OFF',
                  style: TextStyle(
                    fontSize: isCompact ? 10 : 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (!widget.item.isAvailable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Out of Stock',
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityAndPrice(bool isCompact) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuantityControls(isCompact),
        _buildPriceDisplay(isCompact),
      ],
    );
  }

  Widget _buildQuantityControls(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        child: Icon(
          icon,
          size: isCompact ? 16 : 18,
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
