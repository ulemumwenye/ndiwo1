import 'package:flutter/material.dart';
import 'package:butchery_app/locator.dart';
import 'package:butchery_app/models/inventory_item.dart';
import 'package:butchery_app/models/order_item.dart'; // For the cart
import 'package:butchery_app/models/sale.dart';
import 'package:butchery_app/services/inventory_service.dart';
import 'package:butchery_app/services/sales_service.dart'; // Import SalesService

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final InventoryService _inventoryService = locator<InventoryService>();
  List<InventoryItem> _availableItems = [];
  List<OrderItem> _cart = [];
  bool _isLoadingInventory = true;
  double _currentSaleTotal = 0.0;
  final SalesService _salesService = locator<SalesService>();
  final List<String> _paymentMethods = ['Cash', 'Credit Card', 'Mobile Money'];
  String? _selectedPaymentMethod;
  bool _isProcessingSale = false; // For loading state during sale processing

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  Future<void> _loadInventoryItems() async {
    setState(() { _isLoadingInventory = true; });
    try {
      final items = await _inventoryService.getItems();
      setState(() {
        _availableItems = items.where((item) => item.quantityInStock > 0).toList();
        _isLoadingInventory = false;
      });
    } catch (e) {
      setState(() { _isLoadingInventory = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading inventory: $e')),
      );
    }
  }

  void _addToCart(InventoryItem item, double quantityToAdd) {
    setState(() {
      final existingCartItemIndex = _cart.indexWhere((orderItem) => orderItem.inventoryItemId == item.id);
      double newQuantity;

      if (existingCartItemIndex != -1) {
        OrderItem existingOrderItem = _cart[existingCartItemIndex];
        newQuantity = existingOrderItem.quantitySold + quantityToAdd;

        if (newQuantity > item.quantityInStock) {
          newQuantity = item.quantityInStock; // Cap at stock
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Not enough stock for ${item.name}. Quantity set to ${newQuantity.toStringAsFixed(2)}.')),
            );
          }
        }
        // Update existing item
        _cart[existingCartItemIndex] = OrderItem(
          inventoryItemId: existingOrderItem.inventoryItemId,
          itemName: existingOrderItem.itemName,
          quantitySold: newQuantity,
          priceAtSale: item.price, // Use current item price
        );
      } else {
        newQuantity = quantityToAdd;
        if (newQuantity > item.quantityInStock) { // Should be caught by dialog, but double check
          newQuantity = item.quantityInStock;
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Not enough stock for ${item.name}. Quantity set to ${newQuantity.toStringAsFixed(2)}.')),
            );
          }
        }
        _cart.add(OrderItem(
          inventoryItemId: item.id,
          itemName: item.name,
          quantitySold: newQuantity,
          priceAtSale: item.price,
        ));
      }
      _calculateTotal();
    });
  }

  void _incrementCartItemQuantity(OrderItem cartItem) {
    setState(() {
      InventoryItem? inventoryItem;
      try {
        inventoryItem = _availableItems.firstWhere((item) => item.id == cartItem.inventoryItemId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Original item for ${cartItem.itemName} not found in available stock list.')),
          );
        }
        return;
      }

      if (cartItem.quantitySold < inventoryItem.quantityInStock) {
        // Find the item in the cart and update its quantity
        final cartItemIndex = _cart.indexWhere((ci) => ci.inventoryItemId == cartItem.inventoryItemId);
        if (cartItemIndex != -1) {
           _cart[cartItemIndex] = OrderItem(
            inventoryItemId: cartItem.inventoryItemId,
            itemName: cartItem.itemName,
            quantitySold: cartItem.quantitySold + 1,
            priceAtSale: cartItem.priceAtSale,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Max stock reached for ${cartItem.itemName}')),
          );
        }
      }
      _calculateTotal();
    });
  }

  void _decrementCartItemQuantity(OrderItem cartItem) {
    setState(() {
      final cartItemIndex = _cart.indexWhere((ci) => ci.inventoryItemId == cartItem.inventoryItemId);
      if (cartItemIndex != -1) { // Should always be found if called from cart item
        if (_cart[cartItemIndex].quantitySold > 1) {
          _cart[cartItemIndex] = OrderItem(
            inventoryItemId: cartItem.inventoryItemId,
            itemName: cartItem.itemName,
            quantitySold: cartItem.quantitySold - 1,
            priceAtSale: cartItem.priceAtSale,
          );
        } else {
          // If quantity is 1, decrementing removes it.
          _cart.removeAt(cartItemIndex);
        }
      }
      _calculateTotal();
    });
  }

  Future<void> _showQuantityDialog(InventoryItem item) async {
    final quantityEditingController = TextEditingController(text: '1'); // Renamed
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter quantity for ${item.name}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: quantityEditingController, // Renamed
              autofocus: true, // Added autofocus
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter quantity';
                final qty = double.tryParse(value);
                if (qty == null) return 'Invalid number';
                if (qty <= 0) return 'Quantity must be positive';

                // Check against available stock, considering what might already be in cart
                double currentInCartQty = 0;
                final existingCartItemIndex = _cart.indexWhere((orderItem) => orderItem.inventoryItemId == item.id);
                if (existingCartItemIndex != -1) {
                    currentInCartQty = _cart[existingCartItemIndex].quantitySold;
                }
                // The new quantity being added + what's in cart should not exceed total stock
                // Or, if dialog is for SETTING total quantity, then qty <= item.quantityInStock
                // For now, assuming dialog is for ADDING quantity, so qty being entered must be available
                if (qty > (item.quantityInStock - currentInCartQty) && existingCartItemIndex != -1 ) {
                     return 'Not enough stock. Available to add: ${(item.quantityInStock - currentInCartQty).toStringAsFixed(2)}';
                } else if (qty > item.quantityInStock && existingCartItemIndex == -1) {
                     return 'Not enough stock. Available: ${item.quantityInStock.toStringAsFixed(2)}';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add to Cart'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(double.parse(quantityEditingController.text)); // Renamed
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null && result > 0) {
      _addToCart(item, result);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) { // Dispose using addPostFrameCallback
      quantityEditingController.dispose();
    });
  }

  void _removeFromCart(OrderItem orderItemToRemove) {
    setState(() {
      _cart.removeWhere((item) => item.inventoryItemId == orderItemToRemove.inventoryItemId);
      _calculateTotal();
    });
  }

  Future<void> _showFinalizeSaleDialog() async {
    if (_cart.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart is empty! Add items to proceed.')),
        );
      }
      return;
    }

    _selectedPaymentMethod = _paymentMethods[0]; // Default selection
    final saleNotesController = TextEditingController(); // Renamed
    final formKey = GlobalKey<FormState>();

    final bool? saleConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Finalize Sale'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Total Amount: \$${_currentSaleTotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      value: _selectedPaymentMethod,
                      items: _paymentMethods.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          _selectedPaymentMethod = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a payment method' : null,
                    ),
                    TextFormField(
                      controller: saleNotesController, // Renamed
                      decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                child: const Text('Confirm Sale'),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                     Navigator.of(context).pop(true); // Sale confirmed
                  }
                },
              ),
            ],
          );
        });
      },
    );

    if (saleConfirmed == true && _selectedPaymentMethod != null) {
      await _processSale(saleNotesController.text); // Use renamed controller
    }
    WidgetsBinding.instance.addPostFrameCallback((_) { // Dispose using addPostFrameCallback
      saleNotesController.dispose();
    });
  }

  Future<void> _processSale(String notes) async {
    setState(() {
      _isProcessingSale = true;
    });

    final newSale = Sale(
      id: '', // Let SalesService generate it
      orderItems: List<OrderItem>.from(_cart), // Create a copy
      totalAmount: _currentSaleTotal,
      saleDate: DateTime.now(),
      paymentMethod: _selectedPaymentMethod!,
      notes: notes.isEmpty ? null : notes,
    );

    try {
      await _salesService.recordSale(newSale);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale recorded successfully! ID: ${newSale.id}')),
        );
      }
      setState(() {
        _cart.clear();
        _calculateTotal(); // This will set total to 0.0
        _selectedPaymentMethod = null;
        _loadInventoryItems(); // Refresh inventory list
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording sale: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isProcessingSale = false; });
      }
    }
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var orderItem in _cart) {
      total += orderItem.priceAtSale * orderItem.quantitySold;
    }
    setState(() {
      _currentSaleTotal = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Sale'),
      ),
      body: Column(
        children: [
          // Part 1: Inventory List
          Expanded(
            flex: 2, // Give more space to inventory list
            child: _isLoadingInventory
                ? const Center(child: CircularProgressIndicator())
                : _availableItems.isEmpty
                    ? const Center(child: Text('No items available in inventory.'))
                    : ListView.builder(
                        itemCount: _availableItems.length,
                        itemBuilder: (context, index) {
                          final item = _availableItems[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text('Stock: ${item.quantityInStock.toStringAsFixed(2)} ${item.unit} - Price: \$${item.price.toStringAsFixed(2)}/${item.unit}'),
                            onTap: () => _showQuantityDialog(item),
                          );
                        },
                      ),
          ),
          // Divider
          const Divider(height: 1, thickness: 1),
          // Part 2: Cart Summary
          Expanded(
            flex: 1, // Give less space to cart summary
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Cart (${_cart.length} items)', style: Theme.of(context).textTheme.titleLarge),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text('Cart is empty.'))
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, index) {
                              final cartItem = _cart[index];
                              return ListTile(
                                leading: Text('\$${(cartItem.priceAtSale * cartItem.quantitySold).toStringAsFixed(2)}'),
                                title: Text(cartItem.itemName),
                                subtitle: Text('Price: \$${cartItem.priceAtSale.toStringAsFixed(2)}/unit'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => _decrementCartItemQuantity(cartItem),
                                      tooltip: 'Decrease quantity',
                                    ),
                                    Text(cartItem.quantitySold.toStringAsFixed(0)), // Assuming whole numbers for display
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => _incrementCartItemQuantity(cartItem),
                                      tooltip: 'Increase quantity',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _removeFromCart(cartItem),
                                      tooltip: 'Remove from cart',
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text('Total: \$${_currentSaleTotal.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_cart.isEmpty || _isProcessingSale) ? null : _showFinalizeSaleDialog,
                      child: _isProcessingSale ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Finalize Sale'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
