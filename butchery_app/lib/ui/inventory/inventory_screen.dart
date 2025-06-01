import 'package:flutter/material.dart';
import 'package:butchery_app/locator.dart';
import 'package:butchery_app/models/inventory_item.dart';
import 'package:butchery_app/services/inventory_service.dart';
import 'package:butchery_app/ui/inventory/add_inventory_item_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = locator<InventoryService>();
  List<InventoryItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Initially, add some dummy data for testing UI if service is empty
      List<InventoryItem> currentItems = await _inventoryService.getItems();
      if (currentItems.isEmpty) {
        await _inventoryService.addItem(InventoryItem(id: '1', name: 'Test Beef', category: 'Beef', price: 25.0, unit: 'kg', quantityInStock: 10.0, dateAdded: DateTime.now(), lastUpdated: DateTime.now(), description: 'Prime cut beef'));
        await _inventoryService.addItem(InventoryItem(id: '2', name: 'Test Chicken', category: 'Poultry', price: 15.0, unit: 'kg', quantityInStock: 20.0, dateAdded: DateTime.now(), lastUpdated: DateTime.now(), description: 'Whole chicken'));
        currentItems = await _inventoryService.getItems(); // Re-fetch after adding
      }
      setState(() {
        _items = currentItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No items in inventory.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text('${item.category} - ${item.quantityInStock.toStringAsFixed(2)} ${item.unit}'),
                      trailing: Text('\$${item.price.toStringAsFixed(2)}/${item.unit}'),
                      onTap: () {
                        // TODO: Navigate to EditInventoryItemScreen(item)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tapped on ${item.name} - TODO Edit')),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const AddInventoryItemScreen()),
          );
          // If an item was added (indicated by pop(true) from AddInventoryItemScreen),
          // refresh the list.
          if (result == true) {
            _loadInventoryItems();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
