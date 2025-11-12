import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../checkout/place_order_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (cartProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart (${cartProvider.itemCount})'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartProvider.items.length,
              itemBuilder: (context, index) {
                final item = cartProvider.items[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            image: item.productImage.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(item.productImage),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                              Text(
                                item.productName,
                                style: TextStyle(
                      fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              Text(
                                '₹${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                      color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                    ),
                  ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        cartProvider.updateQuantity(
                                          authProvider.user!.uid,
                                          item.productId,
                                          item.quantity - 1,
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.remove_circle_outline),
                                    iconSize: 20,
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      cartProvider.updateQuantity(
                                        authProvider.user!.uid,
                                        item.productId,
                                        item.quantity + 1,
                                      );
                                    },
                                    icon: Icon(Icons.add_circle_outline),
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            cartProvider.removeItem(
                              authProvider.user!.uid,
                              item.productId,
                            );
                          },
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      '₹${cartProvider.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
              onPressed: () {
                      if (!authProvider.userModel!.hasDeliveryDetails) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please add delivery details in profile')),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceOrderScreen(items: cartProvider.items),
                        ),
                      );
              },
              style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                ),
              ),
                    child: Text(
                'Proceed to Checkout',
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
}