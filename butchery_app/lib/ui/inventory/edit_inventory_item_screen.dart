import 'package:flutter/material.dart';
import 'package:butchery_app/locator.dart';
import 'package:butchery_app/models/inventory_item.dart';
import 'package:butchery_app/services/inventory_service.dart';

class EditInventoryItemScreen extends StatefulWidget {
  final InventoryItem itemToEdit;

  const EditInventoryItemScreen({super.key, required this.itemToEdit});

  @override
  State<EditInventoryItemScreen> createState() => _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState extends State<EditInventoryItemScreen> {
  final InventoryService _inventoryService = locator<InventoryService>();
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _supplierNameController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.itemToEdit.name);
    _descriptionController = TextEditingController(text: widget.itemToEdit.description);
    _categoryController = TextEditingController(text: widget.itemToEdit.category);
    _priceController = TextEditingController(text: widget.itemToEdit.price.toString());
    _quantityController = TextEditingController(text: widget.itemToEdit.quantityInStock.toString());
    _unitController = TextEditingController(text: widget.itemToEdit.unit);
    _supplierNameController = TextEditingController(text: widget.itemToEdit.supplierName);
  }

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

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      try {
        final updatedItem = InventoryItem(
          id: widget.itemToEdit.id, // Keep original ID
          name: _nameController.text,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          category: _categoryController.text,
          price: double.tryParse(_priceController.text) ?? widget.itemToEdit.price,
          unit: _unitController.text,
          quantityInStock: double.tryParse(_quantityController.text) ?? widget.itemToEdit.quantityInStock,
          supplierName: _supplierNameController.text.isEmpty ? null : _supplierNameController.text,
          dateAdded: widget.itemToEdit.dateAdded, // Keep original dateAdded
          lastUpdated: DateTime.now(), // Update lastUpdated time
        );

        await _inventoryService.updateItem(widget.itemToEdit.id, updatedItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item updated successfully!')),
          );
          Navigator.of(context).pop(true); // Pop with a result indicating success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating item: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isSaving = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.itemToEdit.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
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
                      onPressed: _updateItem,
                      child: const Text('Save Changes'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
