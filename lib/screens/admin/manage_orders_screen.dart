import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.loadAllOrders();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Orders'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: orderProvider.orders.isEmpty
          ? Center(child: Text('No orders available'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: orderProvider.orders.length,
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(order.orderDate),
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        _buildStatusChip(order.status),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Phone: ${order.phone}'),
                            Text('Address: ${order.deliveryAddress}'),
                            Text('City: ${order.city}'),
                            Text('Postal Code: ${order.postalCode}'),
                            Divider(height: 24),
                            Text(
                              'Order Items',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: order.items.length,
                              itemBuilder: (context, i) {
                                final item = order.items[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.productName} x${item.quantity}',
                                        ),
                                      ),
                                      Text(
                                        'RS${item.totalPrice.toStringAsFixed(0)}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'RS${order.totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Update Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildStatusButton(
                                  order,
                                  'confirmed',
                                  'Confirm',
                                  Colors.blue,
                                ),
                                _buildStatusButton(
                                  order,
                                  'shipped',
                                  'Ship',
                                  Colors.purple,
                                ),
                                _buildStatusButton(
                                  order,
                                  'delivered',
                                  'Deliver',
                                  Colors.green,
                                ),
                                _buildStatusButton(
                                  order,
                                  'cancelled',
                                  'Cancel',
                                  Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'Confirmed';
        break;
      case 'shipped':
        color = Colors.purple;
        label = 'Shipped';
        break;
      case 'delivered':
        color = Colors.green;
        label = 'Delivered';
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    OrderModel order,
    String status,
    String label,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: order.status == status
          ? null
          : () async {
              final orderProvider = Provider.of<OrderProvider>(
                context,
                listen: false,
              );
              bool success = await orderProvider.updateOrderStatus(
                order.id,
                status,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order status updated')),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: order.status == status ? Colors.grey : color,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}