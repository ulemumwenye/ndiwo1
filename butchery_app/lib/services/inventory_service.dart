import '../models/inventory_item.dart';
import 'dart:async'; // Required for Future

class InventoryService {
  final List<InventoryItem> _items = [];

  // Returns a copy of the current list of items.
  Future<List<InventoryItem>> getItems() async {
    // Return a copy to prevent external modification of the internal list
    return List<InventoryItem>.from(_items);
  }

  // Returns an item by its ID, or null if not found.
  Future<InventoryItem?> getItemById(String id) async {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null; // Not found
    }
  }

  // Adds a new item to the list.
  // Assumes the item comes with a pre-generated ID.
  Future<InventoryItem> addItem(InventoryItem item) async {
    // For simplicity, we're not checking for ID uniqueness here,
    // but in a real app, this would be crucial.
    // Also, the ID should ideally be generated here if not provided,
    // but the InventoryItem constructor requires it.
    _items.add(item);
    return item;
  }

  // Updates an existing item with the given ID.
  // Returns the updated item, or null if the item was not found.
  Future<InventoryItem?> updateItem(String id, InventoryItem itemToUpdate) async {
    int index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      // Ensure the ID of the itemToUpdate matches the id parameter,
      // or update the ID of the item at the found index if it's meant to be changeable (not typical for IDs).
      // For this implementation, we assume itemToUpdate's ID is the new ID if it differs,
      // but more robustly, you might prevent ID changes or handle them explicitly.
      // Let's assume itemToUpdate comes with the correct ID or the ID is not meant to be updated via this method.
      // If itemToUpdate's id is different, it implies we're replacing the item at 'id' with a new item that has a potentially new ID.
      // However, the method signature implies 'id' is the key.
      // A safer approach for updating is to ensure itemToUpdate.id == id or use a different model for updates that doesn't include ID.

      // For now, let's ensure the id of the item being updated remains consistent,
      // and other fields are taken from itemToUpdate.
      InventoryItem updatedItemInstance = InventoryItem(
        id: id, // Keep original ID
        name: itemToUpdate.name,
        description: itemToUpdate.description,
        category: itemToUpdate.category,
        price: itemToUpdate.price,
        unit: itemToUpdate.unit,
        quantityInStock: itemToUpdate.quantityInStock,
        supplierName: itemToUpdate.supplierName,
        dateAdded: _items[index].dateAdded, // Keep original dateAdded
        lastUpdated: DateTime.now(), // Update lastUpdated timestamp
      );
      _items[index] = updatedItemInstance;
      return _items[index];
    }
    return null; // Item not found
  }

  // Removes an item with the given ID from the list.
  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  // Returns a list of items where quantityInStock is at or below the given threshold.
  Future<List<InventoryItem>> getLowStockItems(double threshold) async {
    final items = await getItems(); // Uses the existing method to get all items
    return items.where((item) => item.quantityInStock <= threshold).toList();
  }
}
