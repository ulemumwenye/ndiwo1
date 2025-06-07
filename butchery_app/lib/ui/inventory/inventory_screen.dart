import 'package:flutter/material.dart';
import 'package:butchery_app/locator.dart';
import 'package:butchery_app/models/inventory_item.dart';
import 'package:butchery_app/services/inventory_service.dart';
import 'package:butchery_app/ui/inventory/add_inventory_item_screen.dart';
import 'package:butchery_app/ui/inventory/edit_inventory_item_screen.dart'; // Import EditScreen

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _inventoryService = locator<InventoryService>();
  List<InventoryItem> _items = [];
  List<InventoryItem> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterItems();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    if (_searchQuery.isEmpty) {
      _filteredItems = List<InventoryItem>.from(_items);
    } else {
      _filteredItems = _items.where((item) {
        final nameLower = item.name.toLowerCase();
        final categoryLower = item.category.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        return nameLower.contains(queryLower) || categoryLower.contains(queryLower);
      }).toList();
    }
  }

  Future<void> _loadInventoryItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      List<InventoryItem> currentItems = await _inventoryService.getItems();
      if (currentItems.isEmpty) {
        await _inventoryService.addItem(InventoryItem(id: '1', name: 'Test Beef', category: 'Beef', price: 25.0, unit: 'kg', quantityInStock: 10.0, dateAdded: DateTime.now(), lastUpdated: DateTime.now(), description: 'Prime cut beef'));
        await _inventoryService.addItem(InventoryItem(id: '2', name: 'Test Chicken', category: 'Poultry', price: 15.0, unit: 'kg', quantityInStock: 20.0, dateAdded: DateTime.now(), lastUpdated: DateTime.now(), description: 'Whole chicken'));
        currentItems = await _inventoryService.getItems();
      }
      setState(() {
        _items = currentItems;
        _isLoading = false;
      });
      _filterItems(); // Initialize/apply filter after loading items
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Inventory (Name or Category)',
                hintText: 'Enter item name or category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No items in inventory. Add some!')) // Updated text
                    : _filteredItems.isEmpty && _searchQuery.isNotEmpty
                        ? Center(child: Text('No results found for "$_searchQuery".'))
                        : RefreshIndicator(
                            onRefresh: _loadInventoryItems,
                            child: ListView.builder(
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                return Dismissible(
                                  key: Key(item.id),
                                  onDismissed: (direction) async {
                                    final String itemId = item.id;
                                    final String itemName = item.name;

                                    // Optimistic removal from UI state
                                    setState(() {
                                      _items.removeWhere((i) => i.id == itemId);
                                      _filterItems(); // Re-filter the list
                                    });

                                    try {
                                      await _inventoryService.deleteItem(itemId);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${itemName} deleted successfully')),
                                        );
                                      }
                                    } catch (e) {
                                      // Revert optimistic update by reloading data
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error deleting ${itemName}: $e. Please refresh.')),
                                        );
                                      }
                                      _loadInventoryItems(); // Reload to get consistent state
                                    }
                                  },
                                  background: Container(
                                    color: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    alignment: Alignment.centerLeft,
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.start, children: [Icon(Icons.delete, color: Colors.white), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.white))]),
                                  ),
                                  secondaryBackground: Container(
                                    color: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    alignment: Alignment.centerRight,
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Delete', style: TextStyle(color: Colors.white)), SizedBox(width: 8), Icon(Icons.delete, color: Colors.white)]),
                                  ),
                                  child: ListTile(
                                    title: Text(item.name),
                                    subtitle: Text('${item.category} - ${item.quantityInStock.toStringAsFixed(1)} ${item.unit}'), // Changed to toFixed(1)
                                    trailing: Text('\$${item.price.toStringAsFixed(2)}/${item.unit}'),
                                    onTap: () async {
                                      final result = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(
                                          builder: (context) => EditInventoryItemScreen(itemToEdit: item),
                                        ),
                                      );
                                      if (result == true && mounted) { // Added mounted check
                                        _loadInventoryItems();
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (context) => const AddInventoryItemScreen()),
            );
            if (result == true && mounted) { // Added mounted check
              _loadInventoryItems();
            }
          },
          tooltip: 'Add New Item', // Added tooltip
          child: const Icon(Icons.add),
        ),
      );
    }
  }
