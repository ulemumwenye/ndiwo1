import 'package:flutter/material.dart';
import 'package:butchery_app/locator.dart';
import 'package:butchery_app/services/inventory_service.dart';
import 'package:butchery_app/services/sales_service.dart';
import 'package:butchery_app/ui/main_app_shell.dart'; // To switch tabs
import 'package:butchery_app/ui/sales/sales_history_screen.dart'; // Import SalesHistoryScreen
import 'package:butchery_app/models/inventory_item.dart'; // Import InventoryItem
import 'package:butchery_app/ui/inventory/edit_inventory_item_screen.dart'; // Import EditInventoryItemScreen
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final InventoryService _inventoryService = locator<InventoryService>();
  final SalesService _salesService = locator<SalesService>();

  int _totalInventoryItems = 0;
  int _totalSalesCount = 0;
  double _totalSalesAmount = 0.0;
  List<InventoryItem> _lowStockItems = [];
  final double _lowStockThreshold = 5.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final inventoryItems = await _inventoryService.getItems();
      final sales = await _salesService.getSales();
      final totalAmount = await _salesService.getTotalSalesAmount();
      final lowStock = await _inventoryService.getLowStockItems(_lowStockThreshold);

      if (!mounted) return;
      setState(() {
        _totalInventoryItems = inventoryItems.length;
        _totalSalesCount = sales.length;
        _totalSalesAmount = totalAmount;
        _lowStockItems = lowStock;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard data: $e')),
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
  }

  void _navigateToTabInShell(int tabIndex) {
    final mainAppShellState = context.findAncestorStateOfType<_MainAppShellState>();
    if (mainAppShellState != null) {
        mainAppShellState.navigateToTab(tabIndex);
    } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Could not switch tabs.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: <Widget>[
                  Card(
                    elevation: 2.0,
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2_outlined, size: 40, color: Colors.blue),
                      title: const Text('Total Inventory Items'),
                      trailing: Text(_totalInventoryItems.toString(), style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2.0,
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long_outlined, size: 40, color: Colors.green),
                      title: const Text('Total Sales Transactions'),
                      trailing: Text(_totalSalesCount.toString(), style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2.0,
                    child: ListTile(
                      leading: const Icon(Icons.attach_money_outlined, size: 40, color: Colors.orange),
                      title: const Text('Total Sales Amount'),
                      trailing: Text('\$${_totalSalesAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Record New Sale'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _navigateToTabInShell(2), // Assuming Sales is tab index 2
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.inventory),
                    label: const Text('Manage Inventory'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => _navigateToTabInShell(1), // Assuming Inventory is tab index 1
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.history),
                    label: const Text('View Sales History'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2.0,
                    child: ExpansionTile(
                      title: Text('Low Stock Alerts (<= ${_lowStockThreshold.toStringAsFixed(0)})', style: TextStyle(color: _lowStockItems.any((item) => item.quantityInStock <= _lowStockThreshold / 2) ? Colors.red : Colors.orangeAccent)),
                      leading: Icon(Icons.warning_amber_outlined, color: _lowStockItems.any((item) => item.quantityInStock <= _lowStockThreshold / 2) ? Colors.red : Colors.orangeAccent),
                      initiallyExpanded: _lowStockItems.isNotEmpty,
                      children: <Widget>[
                        if (_lowStockItems.isEmpty)
                          const ListTile(title: Text('No items currently low on stock.')),
                        ..._lowStockItems.map((item) {
                          return ListTile(
                            title: Text(item.name),
                            trailing: Text('Stock: ${item.quantityInStock.toStringAsFixed(1)} ${item.unit}', style: TextStyle(color: item.quantityInStock <=_lowStockThreshold / 2 ? Colors.red : Colors.orangeAccent)),
                            onTap: () {
                              Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => EditInventoryItemScreen(itemToEdit: item),
                                ),
                              ).then((updated) {
                                if (updated == true) {
                                  _refreshData();
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
