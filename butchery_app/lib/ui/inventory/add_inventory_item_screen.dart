import 'package:flutter/material.dart';
import 'package:butchery_app/locator.dart';
import 'package:butchery_app/models/inventory_item.dart';
import 'package:butchery_app/services/inventory_service.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class AddInventoryItemScreen extends StatefulWidget {
  const AddInventoryItemScreen({super.key});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final InventoryService _inventoryService = locator<InventoryService>();
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid(); // Make it const if Uuid() constructor is const

  // TextEditingControllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(); // Could be a Dropdown later
  final _supplierNameController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _supplierNameController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      try {
        final newItem = InventoryItem(
          id: _uuid.v4(), // Generate a unique ID
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          category: _categoryController.text,
          price: double.tryParse(_priceController.text) ?? 0.0,
          unit: _unitController.text,
          quantityInStock: double.tryParse(_quantityController.text) ?? 0.0,
          supplierName: _supplierNameController.text.isEmpty ? null : _supplierNameController.text,
          dateAdded: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        await _inventoryService.addItem(newItem);

        if (mounted) { // Check if widget is still in tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added successfully!')),
          );
          Navigator.of(context).pop(true); // Pop with a result indicating success
        }
      } catch (e) {
        if (mounted) { // Check if widget is still in tree
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding item: $e')),
          );
        }
      } finally {
        if (mounted) { // Check if widget is still in tree
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Use ListView for scrollability on smaller screens
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (Optional)'),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a category' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a price';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  if (double.parse(value) < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity in Stock'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a quantity';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  if (double.parse(value) < 0) return 'Quantity cannot be negative';
                  return null;
                },
              ),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unit (e.g., kg, piece)'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a unit' : null,
              ),
              TextFormField(
                controller: _supplierNameController,
                decoration: const InputDecoration(labelText: 'Supplier Name (Optional)'),
              ),
              const SizedBox(height: 20),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveItem,
                      child: const Text('Save Item'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
