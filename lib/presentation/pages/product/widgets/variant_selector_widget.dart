// lib/presentation/pages/product/widgets/variant_selector_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/models/mobile_variant_model.dart';

class VariantSelectorWidget extends StatefulWidget {
  final MobileVariantSelector variantData;
  final Function(String? selectedColor, String? selectedSize, int? variantId,
      double? price) onVariantChanged;
  final String? initialColor;
  final String? initialSize;

  const VariantSelectorWidget({
    Key? key,
    required this.variantData,
    required this.onVariantChanged,
    this.initialColor,
    this.initialSize,
  }) : super(key: key);

  @override
  State<VariantSelectorWidget> createState() => _VariantSelectorWidgetState();
}

class _VariantSelectorWidgetState extends State<VariantSelectorWidget> {
  String? _selectedColor;
  String? _selectedSize;
  int? _selectedVariantId;
  double? _selectedPrice;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor ??
        (widget.variantData.colors.isNotEmpty
            ? widget.variantData.colors.first.colorValue
            : null);
    _selectedSize = widget.initialSize;
    // Don't call _updateSelectedVariant() here - remove this line
    // _updateSelectedVariant(); // REMOVE THIS LINE
  }

  void _updateSelectedVariant() {
    if (_selectedColor != null && _selectedSize != null) {
      final colorOption = widget.variantData.colors
          .firstWhere((color) => color.colorValue == _selectedColor);

      try {
        final sizeOption = colorOption.availableSizes
            .firstWhere((size) => size.sizeValue == _selectedSize);

        _selectedVariantId = sizeOption.variantId;
        _selectedPrice = sizeOption.price;
      } catch (e) {
        _selectedVariantId = null;
        _selectedPrice = null;
      }
    } else {
      _selectedVariantId = null;
      _selectedPrice = null;
    }

    widget.onVariantChanged(
        _selectedColor, _selectedSize, _selectedVariantId, _selectedPrice);
  }

  Widget _buildColorSelector() {
    if (widget.variantData.colors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.variantData.colors.length,
            itemBuilder: (context, index) {
              final color = widget.variantData.colors[index];
              final isSelected = _selectedColor == color.colorValue;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color.colorValue;
                    _selectedSize = null; // Reset size when color changes
                    _updateSelectedVariant();
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFEAF4E)
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: color.imageUrl != null
                        ? Image.network(
                            color.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildColorFallback(color);
                            },
                          )
                        : _buildColorFallback(color),
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedColor != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selected: ${widget.variantData.colors.firstWhere((c) => c.colorValue == _selectedColor).colorDisplay}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildColorFallback(MobileColorOption color) {
    return Container(
      decoration: BoxDecoration(
        color: _getColorFromValue(color.colorValue),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          color.colorDisplay.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: _getTextColorForBackground(
                _getColorFromValue(color.colorValue)),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSelector() {
    if (_selectedColor == null) {
      return const SizedBox.shrink();
    }

    final selectedColorOption = widget.variantData.colors
        .firstWhere((color) => color.colorValue == _selectedColor);

    if (selectedColorOption.availableSizes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: selectedColorOption.availableSizes.map((size) {
            final isSelected = _selectedSize == size.sizeValue;
            final isOutOfStock = !size.inStock;

            return GestureDetector(
              onTap: isOutOfStock
                  ? null
                  : () {
                      setState(() {
                        _selectedSize = size.sizeValue;
                        _updateSelectedVariant();
                      });
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFEAF4E)
                      : isOutOfStock
                          ? Colors.grey.shade100
                          : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFEAF4E)
                        : isOutOfStock
                            ? Colors.grey.shade300
                            : Colors.grey.shade400,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      size.sizeDisplay,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isOutOfStock
                                ? Colors.grey.shade500
                                : Colors.black,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (isOutOfStock)
                      Text(
                        'Out of Stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedSize != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Text(
                  'Selected: ${selectedColorOption.availableSizes.firstWhere((s) => s.sizeValue == _selectedSize).sizeDisplay}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (_selectedPrice != null)
                  Text(
                    '₹${_selectedPrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFEAF4E),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getColorFromValue(String colorValue) {
    switch (colorValue.toLowerCase()) {
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
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    // Calculate brightness and return appropriate text color
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColorSelector(),
          if (widget.variantData.colors.isNotEmpty) const SizedBox(height: 24),
          _buildSizeSelector(),
        ],
      ),
    );
  }
}
