class OrderItem {
  String inventoryItemId;
  String itemName; // Name of the item at the time of sale
  double quantitySold;
  double priceAtSale; // Price of the item per unit at the time of sale

  OrderItem({
    required this.inventoryItemId,
    required this.itemName,
    required this.quantitySold,
    required this.priceAtSale,
  });
}
