import 'package:flutter/material.dart';
import 'package:butchery_app/locator.dart';
import 'package:butchery_app/models/sale.dart';
import 'package:butchery_app/services/sales_service.dart';
import 'package:intl/intl.dart'; // For date formatting

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SalesService _salesService = locator<SalesService>();
  List<Sale> _sales = [];
  List<Sale> _filteredSales = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSalesHistory();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterSales();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSales() {
    if (_searchQuery.isEmpty) {
      _filteredSales = List<Sale>.from(_sales);
    } else {
      _filteredSales = _sales.where((sale) {
        final queryLower = _searchQuery.toLowerCase();
        final saleIdLower = sale.id.toLowerCase();
        final paymentMethodLower = sale.paymentMethod.toLowerCase();
        final notesLower = sale.notes?.toLowerCase() ?? '';

        bool itemMatch = sale.orderItems.any((item) =>
            item.itemName.toLowerCase().contains(queryLower) ||
            item.inventoryItemId.toLowerCase().contains(queryLower)
        );

        return saleIdLower.contains(queryLower) ||
               paymentMethodLower.contains(queryLower) ||
               notesLower.contains(queryLower) ||
               itemMatch;
      }).toList();
    }
  }

  Future<void> _loadSalesHistory() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final salesData = await _salesService.getSales();
      // Sort sales by date, most recent first
      salesData.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      if (!mounted) return;
      setState(() {
        _sales = salesData;
        _isLoading = false;
      });
      _filterSales(); // Initialize/apply filter after loading sales
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sales history: $e')),
      );
    }
  }

  void _showSaleDetailsDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sale Details (ID: ...${sale.id.isNotEmpty ? sale.id.substring(sale.id.length - Math.min(6, sale.id.length)) : 'N/A'})'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate)}'),
                Text('Total Amount: \$${sale.totalAmount.toStringAsFixed(2)}'),
                Text('Payment Method: ${sale.paymentMethod}'),
                if (sale.notes != null && sale.notes!.isNotEmpty) Text('Notes: ${sale.notes}'),
                const SizedBox(height: 10),
                const Text('Items Sold:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (sale.orderItems.isEmpty)
                  const Text('No items recorded for this sale.'),
                ...sale.orderItems.map((item) {
                  return ListTile(
                    title: Text(item.itemName),
                    subtitle: Text('Qty: ${item.quantitySold.toStringAsFixed(2)}, Price: \$${item.priceAtSale.toStringAsFixed(2)}/unit'),
                    trailing: Text('Subtotal: \$${(item.quantitySold * item.priceAtSale).toStringAsFixed(2)}'),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalesHistory,
            tooltip: 'Refresh History',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Sales (ID, Payment, Notes, Item Name/ID)',
                hintText: 'Enter search term...',
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
                : _sales.isEmpty
                    ? Center(
                        child: Text(
                          'No sales recorded yet.',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      )
                    : _filteredSales.isEmpty && _searchQuery.isNotEmpty
                        ? Center(child: Text('No sales found for "$_searchQuery".', style: Theme.of(context).textTheme.titleMedium))
                        : RefreshIndicator(
                            onRefresh: _loadSalesHistory,
                            child: ListView.builder(
                              itemCount: _filteredSales.length,
                              itemBuilder: (context, index) {
                                final sale = _filteredSales[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(child: Text((index + 1).toString())),
                          title: Text('Sale ID: ...${sale.id.isNotEmpty ? sale.id.substring(sale.id.length - Math.min(6, sale.id.length)) : 'N/A'}'),
                          subtitle: Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate)}\nTotal: \$${sale.totalAmount.toStringAsFixed(2)} - ${sale.paymentMethod}'),
                          isThreeLine: true,
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () => _showSaleDetailsDialog(sale),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// Helper for Math.min since dart:math is not imported by default in widget files
class Math {
  static int min(int a, int b) => (a < b) ? a : b;
}
