import '../models/sale.dart';
import '../models/order_item.dart';
import '../models/inventory_item.dart'; // Needed for updating inventory
import '../services/inventory_service.dart';
import './notification_service.dart'; // Import NotificationService
import 'dart:async'; // Required for Future

class SalesService {
  final List<Sale> _sales = [];
  final InventoryService _inventoryService;
  final NotificationService _notificationService; // Add NotificationService field

  SalesService(this._inventoryService, this._notificationService); // Update constructor

  // Returns a copy of the current list of sales.
  Future<List<Sale>> getSales() async {
    return List<Sale>.from(_sales);
  }

  // Returns a sale by its ID, or null if not found.
  Future<Sale?> getSaleById(String id) async {
    try {
      return _sales.firstWhere((sale) => sale.id == id);
    } catch (e) {
      return null; // Not found
    }
  }

  // Records a new sale and updates inventory.
  Future<Sale> recordSale(Sale sale) async {
    Sale saleToRecord = sale;
    // Generate ID if not present or is empty.
    // The model requires ID, but this allows flexibility if an empty ID is passed.
    if (saleToRecord.id.isEmpty) {
        String newId = DateTime.now().millisecondsSinceEpoch.toString();
        saleToRecord = Sale(
            id: newId,
            orderItems: sale.orderItems,
            totalAmount: sale.totalAmount,
            saleDate: sale.saleDate,
            paymentMethod: sale.paymentMethod,
            notes: sale.notes
        );
    }

    for (OrderItem orderItem in saleToRecord.orderItems) {
      InventoryItem? inventoryItem = await _inventoryService.getItemById(orderItem.inventoryItemId);

      if (inventoryItem != null) {
        if (inventoryItem.quantityInStock >= orderItem.quantitySold) {
          // Create a new InventoryItem instance for the update
          InventoryItem updatedInventoryItem = InventoryItem(
            id: inventoryItem.id,
            name: inventoryItem.name,
            description: inventoryItem.description,
            category: inventoryItem.category,
            price: inventoryItem.price, // Price in inventory might be different from priceAtSale
            unit: inventoryItem.unit,
            quantityInStock: inventoryItem.quantityInStock - orderItem.quantitySold,
            supplierName: inventoryItem.supplierName,
            dateAdded: inventoryItem.dateAdded,
            lastUpdated: DateTime.now(),
          );
          await _inventoryService.updateItem(inventoryItem.id, updatedInventoryItem);
        } else {
          // Handle insufficient stock - for now, print a message
          print('Insufficient stock for item ID: ${orderItem.inventoryItemId}, name: ${inventoryItem.name}. Sale of ${orderItem.quantitySold} requested, ${inventoryItem.quantityInStock} available.');
          // Depending on business logic, you might throw an exception here or handle it differently
        }
      } else {
        // Handle item not found - for now, print a message
        print('Inventory item not found for ID: ${orderItem.inventoryItemId}. Cannot update stock.');
        // Depending on business logic, you might throw an exception here
      }
    }

    _sales.add(saleToRecord);
    await _notificationService.showSaleNotification(saleToRecord); // Call notification service
    return saleToRecord;
  }

  // Calculates and returns the sum of totalAmount for all sales.
  Future<double> getTotalSalesAmount() async {
    double total = 0;
    for (Sale sale in _sales) {
      total += sale.totalAmount;
    }
    return total;
  }

  // Returns a map where keys are payment methods and values are total sales amounts for that method.
  Future<Map<String, double>> getSalesByPaymentMethod() async {
    Map<String, double> salesByMethod = {};
    for (Sale sale in _sales) {
      salesByMethod.update(
        sale.paymentMethod,
        (existingTotal) => existingTotal + sale.totalAmount,
        ifAbsent: () => sale.totalAmount,
      );
    }
    return salesByMethod;
  }
}
