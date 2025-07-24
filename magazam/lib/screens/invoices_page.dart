import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:magazam/screens/create_invoice_page.dart';
import '../bloc/invoice/invoice_bloc.dart';
import '../bloc/invoice/invoice_event.dart';
import '../bloc/invoice/invoice_state.dart';
import '../bloc/customer/customer_bloc.dart';
import '../bloc/customer/customer_event.dart';
import '../bloc/customer/customer_state.dart';
import '../bloc/stock/stock_bloc.dart';
import '../bloc/stock/stock_event.dart';
import '../bloc/stock/stock_state.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/stock_item.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchController = TextEditingController();
  InvoiceStatus? _selectedStatusFilter;

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
        title: const Text('Invoices'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<InvoiceStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              setState(() {
                _selectedStatusFilter = status;
              });
              context.read<InvoiceBloc>().add(
                InvoiceLoadRequested(status: status?.name),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Invoices'),
              ),
              ...InvoiceStatus.values.map((status) => PopupMenuItem(
                value: status,
                child: Text(status.displayName),
              )),
            ],
          ),
        ],
      ),
      body: BlocListener<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceError) {
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
                  hintText: 'Search invoices...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.orange[600]!),
                  ),
                ),
              ),
            ),
            
            // Filter chips
            if (_selectedStatusFilter != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Chip(
                      label: Text(_selectedStatusFilter!.displayName),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedStatusFilter = null;
                        });
                        context.read<InvoiceBloc>().add(InvoiceLoadRequested());
                      },
                    ),
                  ],
                ),
              ),
            
            // Invoices List
            Expanded(
              child: BlocBuilder<InvoiceBloc, InvoiceState>(
                builder: (context, state) {
                  if (state is InvoiceLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is InvoiceLoaded) {
                    // Filter invoices based on search query
                    final query = _searchController.text.toLowerCase();
                    final invoices = query.isEmpty 
                        ? state.invoices 
                        : state.invoices.where((invoice) =>
                            invoice.invoiceNumber.toLowerCase().contains(query) ||
                            invoice.totalAmount.toString().contains(query)).toList();
                    
                    if (invoices.isEmpty) {
                      return const Center(
                        child: Text(
                          'No invoices found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(invoice.status).withOpacity(0.2),
                              child: Icon(
                                Icons.receipt_long,
                                color: _getStatusColor(invoice.status),
                              ),
                            ),
                            title: Text(
                              'Invoice #${invoice.invoiceNumber}',
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
                                  'Total: ${invoice.totalAmount.toStringAsFixed(2)} EGP',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Items: ${invoice.items.length}',
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
                                    color: _getStatusColor(invoice.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    invoice.status.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(invoice.status),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(invoice.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showInvoiceOptions(context, invoice),
                          ),
                        );
                      },
                    );
                  } else if (state is InvoiceError) {
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
                              context.read<InvoiceBloc>().add(InvoiceLoadRequested());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(child: Text('No invoices found'));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateInvoiceDialog(context),
        backgroundColor: Colors.orange[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showInvoiceOptions(BuildContext context, Invoice invoice) {
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
              'Invoice #${invoice.invoiceNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use the original context that has access to InvoiceBloc
                _showInvoiceDetails(context, invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Edit Invoice'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use the original context that has access to InvoiceBloc
                _showEditInvoiceDialog(context, invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.update, color: Colors.green),
              title: const Text('Update Status'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use the original context that has access to InvoiceBloc
                _showStatusUpdateDialog(context, invoice);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Invoice'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                // Use the original context that has access to InvoiceBloc
                _showDeleteConfirmation(context, invoice);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoiceDetails(BuildContext context, Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status:', invoice.status.displayName),
              _buildDetailRow('Total Amount:', '${invoice.totalAmount.toStringAsFixed(2)} EGP'),
              _buildDetailRow('Created:', _formatDate(invoice.createdAt)),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...invoice.items.map((item) => Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Qty: ${item.quantity} × ${item.price.toStringAsFixed(2)} EGP',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.total.toStringAsFixed(2)} EGP',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, Invoice invoice) {
    // Capture the bloc reference BEFORE showing the dialog
    final invoiceBloc = context.read<InvoiceBloc>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: InvoiceStatus.values.map((status) => ListTile(
            leading: Radio<InvoiceStatus>(
              value: status,
              groupValue: invoice.status,
              onChanged: (value) {
                if (value != null) {
                  // Use the captured bloc reference
                  invoiceBloc.add(InvoiceStatusUpdateRequested(
                    invoiceId: invoice.id,
                    status: value,
                  ));
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(status.displayName),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Invoice invoice) {
    // Capture the bloc reference BEFORE showing the dialog
    final invoiceBloc = context.read<InvoiceBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete Invoice #${invoice.invoiceNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Use the captured bloc reference
              invoiceBloc.add(InvoiceDeleteRequested(invoice.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateInvoiceDialog(BuildContext context) {
    // Capture the bloc reference BEFORE navigation
    final invoiceBloc = context.read<InvoiceBloc>();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: invoiceBloc), // Use the captured bloc
            BlocProvider(create: (context) => CustomerBloc()..add(CustomerLoadRequested())),
            BlocProvider(create: (context) => StockBloc()..add(StockLoadRequested())),
          ],
          child: const CreateInvoicePage(),
        ),
      ),
    );
  }

  void _showEditInvoiceDialog(BuildContext context, Invoice invoice) {
    // Capture the bloc reference BEFORE navigation
    final invoiceBloc = context.read<InvoiceBloc>();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: invoiceBloc), // Use the captured bloc
            BlocProvider(create: (context) => CustomerBloc()..add(CustomerLoadRequested())),
            BlocProvider(create: (context) => StockBloc()..add(StockLoadRequested())),
          ],
          child: CreateInvoicePage(invoice: invoice),
        ),
      ),
    );
  }
}