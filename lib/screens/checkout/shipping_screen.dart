import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import 'order_success_screen.dart';

class ShippingScreen extends StatefulWidget {
  final List<CartItemModel> items;
  final double totalAmount;

  const ShippingScreen({
    Key? key,
    required this.items,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<ShippingScreen> createState() => _ShippingScreenState();
}

class _ShippingScreenState extends State<ShippingScreen> {
  String _selectedPaymentMethod = 'cash_on_delivery';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Method'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Cash on Delivery
                    _buildPaymentOption(
                      value: 'cash_on_delivery',
                      title: 'Cash on Delivery',
                      icon: Icons.money,
                      description: 'Pay when you receive',
                    ),

                    // UPI
                    _buildPaymentOption(
                      value: 'upi',
                      title: 'UPI',
                      icon: Icons.account_balance_wallet,
                      description: 'Pay via UPI apps',
                    ),

                    // Credit/Debit Card
                    _buildPaymentOption(
                      value: 'card',
                      title: 'Credit/Debit Card',
                      icon: Icons.credit_card,
                      description: 'Visa, Mastercard, Rupay',
                    ),

                    // Net Banking
                    _buildPaymentOption(
                      value: 'net_banking',
                      title: 'Net Banking',
                      icon: Icons.account_balance,
                      description: 'All major banks',
                    ),

                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.pink),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your order will be placed after payment confirmation',
                              style: TextStyle(color: Colors.pink.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Total and Place Order
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
                      '₹${widget.totalAmount.toStringAsFixed(0)}',
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
                    onPressed: _isProcessing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isProcessing
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Place Order',
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

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required IconData icon,
    required String description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedPaymentMethod == value
              ? Colors.pink
              : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioListTile(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: (val) {
          setState(() => _selectedPaymentMethod = val.toString());
        },
        title: Row(
          children: [
            Icon(icon, color: Colors.pink),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        activeColor: Colors.pink,
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userModel = authProvider.userModel!;

    final order = OrderModel(
      id: '',
      userId: authProvider.user!.uid,
      items: widget.items,
      totalAmount: widget.totalAmount,
      deliveryAddress: userModel.address!,
      city: userModel.city!,
      postalCode: userModel.postalCode!,
      phone: userModel.phone!,
      paymentMethod: _selectedPaymentMethod,
      orderDate: DateTime.now(),
    );

    bool success = await orderProvider.placeOrder(order);

    setState(() => _isProcessing = false);

    if (success) {
      // Clear cart
      await cartProvider.clearCart(authProvider.user!.uid);
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order')),
      );
    }
  }
}