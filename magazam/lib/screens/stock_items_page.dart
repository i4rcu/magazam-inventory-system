import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/stock/stock_bloc.dart';
import '../bloc/stock/stock_event.dart';
import '../bloc/stock/stock_state.dart';
import '../models/stock_item.dart';

class StockItemsPage extends StatefulWidget {
  const StockItemsPage({super.key});

  @override
  State<StockItemsPage> createState() => _StockItemsPageState();
}

class _StockItemsPageState extends State<StockItemsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Trigger rebuild for search functionality
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Items'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocListener<StockBloc, StockState>(
        listener: (context, state) {
          if (state is StockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.purple[600]!),
                  ),
                ),
              ),
            ),
            
            // Stock Items List
            Expanded(
              child: BlocBuilder<StockBloc, StockState>(
                builder: (context, state) {
                  if (state is StockLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is StockLoaded) {
                    // Filter items based on search query
                    final query = _searchController.text.toLowerCase();
                    final items = query.isEmpty 
                        ? state.stockItems 
                        : state.stockItems.where((item) =>
                            item.name.toLowerCase().contains(query) ||
                            (item.category?.toLowerCase().contains(query) ?? false) ||
                            (item.sku?.toLowerCase().contains(query) ?? false)).toList();
                    
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No items found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple[100],
                              child: Icon(
                                Icons.inventory_2,
                                color: Colors.purple[600],
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Price: ${item.price.toStringAsFixed(2)} EGP',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                if (item.category != null)
                                  Text(
                                    'Category: ${item.category}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                if (item.sku != null)
                                  Text(
                                    'SKU: ${item.sku}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.quantity > 0 
                                        ? Colors.green[100] 
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: item.quantity > 0 
                                          ? Colors.green[800] 
                                          : Colors.red[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'in stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showItemOptions(context, item),
                          ),
                        );
                      },
                    );
                  } else if (state is StockError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<StockBloc>().add(StockLoadRequested());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text('No items found'));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: Colors.purple[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showItemOptions(BuildContext context, StockItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Item'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use the original context that has access to StockBloc
                _showEditItemDialog(context, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Add Stock'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use the original context that has access to StockBloc
                _showQuantityDialog(context, item, 'add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.orange),
              title: const Text('Remove Stock'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use the original context that has access to StockBloc
                _showQuantityDialog(context, item, 'subtract');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Item'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use the original context that has access to StockBloc
                _showDeleteConfirmation(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final skuController = TextEditingController();

    // Capture the bloc reference BEFORE showing the dialog
    final stockBloc = context.read<StockBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  priceController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                // Use the captured bloc reference
                stockBloc.add(
                  StockAddRequested(
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0.0,
                    quantity: int.tryParse(quantityController.text) ?? 0,
                    description: descriptionController.text.isNotEmpty 
                        ? descriptionController.text : null,
                    category: categoryController.text.isNotEmpty 
                        ? categoryController.text : null,
                    sku: skuController.text.isNotEmpty 
                        ? skuController.text : null,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, StockItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final quantityController = TextEditingController(text: item.quantity.toString());
    final descriptionController = TextEditingController(text: item.description ?? '');
    final categoryController = TextEditingController(text: item.category ?? '');
    final skuController = TextEditingController(text: item.sku ?? '');

    // Capture the bloc reference BEFORE showing the dialog
    final stockBloc = context.read<StockBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  priceController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty) {
                // Use the captured bloc reference
                stockBloc.add(
                  StockUpdateRequested(
                    itemId: item.id,
                    name: nameController.text,
                    price: double.tryParse(priceController.text) ?? 0.0,
                    quantity: int.tryParse(quantityController.text) ?? 0,
                    description: descriptionController.text.isNotEmpty 
                        ? descriptionController.text : null,
                    category: categoryController.text.isNotEmpty 
                        ? categoryController.text : null,
                    sku: skuController.text.isNotEmpty 
                        ? skuController.text : null,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, StockItem item, String operation) {
    final quantityController = TextEditingController();
    
    // Capture the bloc reference BEFORE showing the dialog
    final stockBloc = context.read<StockBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${operation == 'add' ? 'Add' : 'Remove'} Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current quantity: ${item.quantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity to ${operation == 'add' ? 'add' : 'remove'}',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (quantityController.text.isNotEmpty) {
                // Use the captured bloc reference
                stockBloc.add(
                  StockQuantityUpdateRequested(
                    itemId: item.id,
                    quantity: int.tryParse(quantityController.text) ?? 0,
                    operation: operation,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StockItem item) {
    // Capture the bloc reference BEFORE showing the dialog
    final stockBloc = context.read<StockBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Use the captured bloc reference
              stockBloc.add(StockDeleteRequested(item.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}