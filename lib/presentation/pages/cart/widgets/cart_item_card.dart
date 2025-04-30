// lib/presentation/pages/cart/widgets/cart_item_card.dart
import 'package:flutter/material.dart';
import '../../../../core/models/cart_item_model.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartItemCard({
    Key? key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 100,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            // Product details
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (item.selectedOptions != null &&
                      item.selectedOptions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        item.selectedOptions!.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF7A2E),
                        ),
                      ),
                      Row(
                        children: [
                          // Remove one button
                          InkWell(
                            onTap: onDecrement,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.remove, size: 16),
                            ),
                          ),

                          // Quantity
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Add one button
                          InkWell(
                            onTap: onIncrement,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.add, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Remove button
                  GestureDetector(
                    onTap: onRemove,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
