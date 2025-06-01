import './order_item.dart'; // Corrected import path

class Sale {
  String id;
  List<OrderItem> orderItems;
  double totalAmount;
  DateTime saleDate;
  String paymentMethod; // e.g., "cash", "card", "mobile_money"
  String? notes;

  Sale({
    required this.id,
    required this.orderItems,
    required this.totalAmount,
    required this.saleDate,
    required this.paymentMethod,
    this.notes,
  });
}
