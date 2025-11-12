import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../checkout/place_order_screen.dart';
import '../../providers/wishlist_provider.dart';
import '../../models/wishlist_item_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product, required String productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _selectedImageIndex = 0;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final reviews = await productProvider.getProductReviews(widget.product.id);
    setState(() => _reviews = reviews);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
  Consumer<WishlistProvider>(
    builder: (context, wishlistProvider, _) {
      final isInWishlist = wishlistProvider.isInWishlist(widget.product.id);
      return IconButton(
        icon: Icon(
          isInWishlist ? Icons.favorite : Icons.favorite_border,
          color: isInWishlist ? Colors.red : null,
        ),
        onPressed: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please login first')),
            );
            return;
          }

          final item = WishlistItemModel(
            productId: widget.product.id,
            productName: widget.product.name,
            productImage: widget.product.images.isNotEmpty 
                ? widget.product.images.first 
                : '',
            price: widget.product.effectivePrice,
            addedAt: DateTime.now(),
          );

          wishlistProvider.addToWishlist(authProvider.user!.uid, item);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isInWishlist 
                    ? 'Removed from wishlist' 
                    : 'Added to wishlist',
              ),
            ),
          );
        },
      );
    },
  ),
],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Images
                  Container(
                    height: 300,
                    child: widget.product.images.isEmpty
                        ? Container(color: Colors.grey.shade200)
                        : PageView.builder(
                            onPageChanged: (index) {
                              setState(() => _selectedImageIndex = index);
                            },
                            itemCount: widget.product.images.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                widget.product.images[index],
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  ),
                  if (widget.product.images.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.product.images.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: _selectedImageIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _selectedImageIndex == index
                                  ? Colors.pink
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name and Price
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            if (widget.product.discountPrice != null) ...[
                              Text(
                                'RS${widget.product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                            Text(
                              'RS${widget.product.effectivePrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            if (widget.product.discountPercentage > 0) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.pink,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${widget.product.discountPercentage}% OFF',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 12),

                        // Rating and Reviews
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              '${widget.product.rating.toStringAsFixed(1)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(${widget.product.reviewCount} Reviews)',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Stock Status
                        Row(
                          children: [
                            Icon(
                              widget.product.stock > 0
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: widget.product.stock > 0
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              widget.product.stock > 0
                                  ? 'In Stock (${widget.product.stock} available)'
                                  : 'Out of Stock',
                              style: TextStyle(
                                color: widget.product.stock > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Quantity Selector
                        Text(
                          'Quantity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() => _quantity--);
                                }
                              },
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_quantity',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_quantity < widget.product.stock) {
                                  setState(() => _quantity++);
                                }
                              },
                              icon: Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Description
                        Text(
                          'Product Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Reviews Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reviews (${_reviews.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: _showAddReviewDialog,
                              child: Text('Add Review'),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length > 3 ? 3 : _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.pink.shade100,
                                          child: Text(
                                            review.userName[0].toUpperCase(),
                                            style: TextStyle(color: Colors.pink),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                review.userName,
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              Row(
                                                children: [
                                                  RatingBarIndicator(
                                                    rating: review.rating,
                                                    itemBuilder: (context, index) => Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                    ),
                                                    itemCount: 5,
                                                    itemSize: 16,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(review.comment),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.product.stock > 0 ? _addToCart : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.pink),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: TextStyle(color: Colors.pink, fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.product.stock > 0 ? _buyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Buy Now',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login first')),
      );
      return;
    }

    final cartItem = CartItemModel(
      productId: widget.product.id,
      productName: widget.product.name,
      productImage: widget.product.images.isNotEmpty ? widget.product.images.first : '',
      price: widget.product.effectivePrice,
      quantity: _quantity,
    );

    await cartProvider.addItem(authProvider.user!.uid, cartItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to cart')),
    );
  }

  void _buyNow() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login first')),
      );
      return;
    }

    // Check if user has delivery details
    if (!authProvider.userModel!.hasDeliveryDetails) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add delivery details in profile')),
      );
      return;
    }

    // Create temporary cart item for direct purchase
    final cartItem = CartItemModel(
      productId: widget.product.id,
      productName: widget.product.name,
      productImage: widget.product.images.isNotEmpty ? widget.product.images.first : '',
      price: widget.product.effectivePrice,
      quantity: _quantity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceOrderScreen(items: [cartItem]),
      ),
    );
  }

  void _showAddReviewDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to add a review')),
      );
      return;
    }

    double rating = 5.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingBar.builder(
              initialRating: 5,
              minRating: 1,
              direction: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (value) => rating = value,
            ),
            SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your review...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (commentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please write a comment')),
                );
                return;
              }

              final review = ReviewModel(
                id: '',
                productId: widget.product.id,
                userId: authProvider.user!.uid,
                userName: authProvider.userModel!.name,
                rating: rating,
                comment: commentController.text,
                createdAt: DateTime.now(),
              );

              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              bool success = await productProvider.addReview(review);

              Navigator.pop(context);

              if (success) {
                _loadReviews();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Review added successfully')),
                );
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}