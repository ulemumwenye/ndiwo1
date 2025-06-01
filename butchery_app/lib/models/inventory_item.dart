class InventoryItem {
  String id;
  String name;
  String? description;
  String category;
  double price;
  String unit; // e.g., "kg", "piece", "liter"
  double quantityInStock;
  String? supplierName;
  DateTime dateAdded;
  DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.quantityInStock,
    this.supplierName,
    required this.dateAdded,
    required this.lastUpdated,
  });
}
