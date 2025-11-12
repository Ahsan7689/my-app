import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../providers/wishlist_provider.dart';
import '../product/product_detail_screen.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Wishlist (${wishlistProvider.itemCount})'),
        actions: [
          if (wishlistProvider.productIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear Wishlist',
              onPressed: () => _showClearConfirmationDialog(context),
            ),
        ],
      ),
      body: _buildBody(context, wishlistProvider),
    );
  }

  Widget _buildBody(BuildContext context, WishlistProvider wishlistProvider) {
    if (wishlistProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (wishlistProvider.productIds.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        message: 'Your wishlist is empty',
        details: 'Add items you love to your wishlist.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: wishlistProvider.productIds.length,
      itemBuilder: (context, index) {
        final productId = wishlistProvider.productIds[index];
        return _WishlistItemCard(productId: productId);
      },
    );
  }

  void _showClearConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Wishlist?'),
        content: const Text('Are you sure you want to remove all items from your wishlist?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Clear All'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<WishlistProvider>(context, listen: false).clearWishlist();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _WishlistItemCard extends StatelessWidget {
  final String productId;

  const _WishlistItemCard({required this.productId});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    return FutureBuilder<ProductModel?>(
      future: productProvider.getProductById(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Optionally show a small error card
          return ErrorState(message: 'Could not load product.');
        }

        final product = snapshot.data!;

        return GestureDetector(
            onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      productId: product.id,
                      product: product, // Pass the already fetched product
                    ),
                  ),
                ),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                             borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images.first,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                                  )
                                : Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Consumer<WishlistProvider>(
                            builder: (context, wishlist, child) => GestureDetector(
                              onTap: () => wishlist.toggleWishlist(product.id),
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.5),
                                radius: 16,
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('₹${product.effectivePrice.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ), 
                  ),
                ],
              ),
            ));
      },
    );
  }
}
