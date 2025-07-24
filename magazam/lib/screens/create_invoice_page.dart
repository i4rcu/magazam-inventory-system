import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/invoice/invoice_bloc.dart';
import '../bloc/invoice/invoice_event.dart';
import '../bloc/customer/customer_bloc.dart';
import '../bloc/customer/customer_state.dart';
import '../bloc/stock/stock_bloc.dart';
import '../bloc/stock/stock_state.dart';
import '../models/invoice.dart';
import '../models/customer.dart';
import '../models/stock_item.dart';

class CreateInvoicePage extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoicePage({super.key, this.invoice});

  @override
  State<CreateInvoicePage> createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  
  Customer? _selectedCustomer;
  InvoiceStatus _selectedStatus = InvoiceStatus.pending;
  List<InvoiceItem> _selectedItems = [];
  bool _isInitialized = false;
  
  // Store the blocs to avoid context issues
  late final InvoiceBloc _invoiceBloc;
  late final CustomerBloc _customerBloc;
  late final StockBloc _stockBloc;
  
  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    
    // Initialize the blocs in initState to avoid context issues
    try {
      _invoiceBloc = context.read<InvoiceBloc>();
      _customerBloc = context.read<CustomerBloc>();
      _stockBloc = context.read<StockBloc>();
    } catch (e) {
      print('Error initializing blocs: $e');
    }
    
    if (_isEditing && widget.invoice != null) {
      _invoiceNumberController.text = widget.invoice!.invoiceNumber;
      _selectedStatus = widget.invoice!.status;
      _selectedItems = List.from(widget.invoice!.items);
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _selectedItems.fold(0.0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Invoice' : 'Create Invoice'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Number
              TextFormField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Invoice Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter invoice number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Customer Selection
              const Text(
                'Select Customer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              BlocBuilder<CustomerBloc, CustomerState>(
                bloc: _customerBloc,
                builder: (context, state) {
                  if (state is CustomerLoaded) {
                    // Initialize customer selection for editing if not already done
                    if (_isEditing && !_isInitialized) {
                      _isInitialized = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _findCustomerForEdit(state.customers);
                      });
                    }
                    
                    return DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Choose a customer',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a customer';
                        }
                        return null;
                      },
                      items: state.customers.map((customer) {
                        return DropdownMenuItem<Customer>(
                          value: customer,
                          child: Text(customer.fullName),
                        );
                      }).toList(),
                      onChanged: (customer) {
                        setState(() {
                          _selectedCustomer = customer;
                        });
                      },
                    );
                  } else if (state is CustomerLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    return const Center(
                      child: Text(
                        'Failed to load customers',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),

              // Status Selection
              const Text(
                'Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<InvoiceStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: InvoiceStatus.values.map((status) {
                  return DropdownMenuItem<InvoiceStatus>(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (status) {
                  if (status != null) {
                    setState(() {
                      _selectedStatus = status;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Items Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items List
              if (_selectedItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No items added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Column(
                  children: _selectedItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'Qty: ${item.quantity} × ${item.price.toStringAsFixed(2)} EGP',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.total.toStringAsFixed(2)} EGP',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 16),

              // Total Amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_totalAmount.toStringAsFixed(2)} EGP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit() ? _submitInvoice : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(
                    _isEditing ? 'Update Invoice' : 'Create Invoice',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _findCustomerForEdit(List<Customer> customers) {
    if (_isEditing && widget.invoice != null && customers.isNotEmpty && mounted) {
      try {
        final customer = customers.firstWhere(
          (c) => c.id == widget.invoice!.customerId,
          orElse: () => customers.first,
        );
        if (mounted) {
          setState(() {
            _selectedCustomer = customer;
          });
        }
      } catch (e) {
        print('Error finding customer: $e');
      }
    }
  }

  void _removeItem(int index) {
    if (mounted && index >= 0 && index < _selectedItems.length) {
      setState(() {
        _selectedItems.removeAt(index);
      });
    }
  }

  bool _canSubmit() {
    return _selectedCustomer != null && 
           _selectedItems.isNotEmpty && 
           _invoiceNumberController.text.isNotEmpty;
  }

  void _showAddItemDialog() {
    try {
      final stockState = _stockBloc.state;
      
      if (stockState is! StockLoaded) {
        _showErrorMessage('Stock data not loaded. Please try again.');
        return;
      }

      final availableItems = stockState.stockItems
          .where((stockItem) => stockItem.quantity > 0)
          .where((stockItem) => !_selectedItems.any((selectedItem) => selectedItem.itemId == stockItem.id))
          .toList();

      if (availableItems.isEmpty) {
        _showErrorMessage('No items available to add');
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add Item'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('Select an item from stock:'),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: availableItems.length,
                    itemBuilder: (context, index) {
                      final stockItem = availableItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(stockItem.name),
                          subtitle: Text(
                            'Price: ${stockItem.price.toStringAsFixed(2)} EGP\n'
                            'Available: ${stockItem.quantity}',
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _selectItem(dialogContext, stockItem),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Select'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error showing dialog: $e');
      _showErrorMessage('Failed to load items: $e');
    }
  }

  void _selectItem(BuildContext dialogContext, StockItem stockItem) {
    if (mounted) {
      Navigator.pop(dialogContext);
      _showQuantityDialog(stockItem);
    }
  }

  void _showQuantityDialog(StockItem stockItem) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _QuantityDialog(
          stockItem: stockItem,
          onItemAdded: (quantity, price) {
            _addItemToInvoice(stockItem, quantity, price);
          },
        );
      },
    );
  }

  void _addItemToInvoice(StockItem stockItem, int quantity, double price) {
    try {
      final existingItemIndex = _selectedItems.indexWhere((item) => item.itemId == stockItem.id);
      if (existingItemIndex != -1) {
        _showErrorMessage('Item already added to invoice');
        return;
      }
      
      final invoiceItem = InvoiceItem(
        itemId: stockItem.id,
        name: stockItem.name,
        quantity: quantity,
        price: price,
      );
      
      if (mounted) {
        setState(() {
          _selectedItems.add(invoiceItem);
        });
        _showSuccessMessage('${stockItem.name} added to invoice');
      }
    } catch (e) {
      print('Error adding item to invoice: $e');
      _showErrorMessage('Failed to add item. Please try again.');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } catch (e) {
        print('Error showing error message: $e');
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Error showing success message: $e');
      }
    }
  }

  void _submitInvoice() {
    try {
      if (!_formKey.currentState!.validate()) {
        _showErrorMessage('Please fill all required fields');
        return;
      }

      if (_selectedCustomer == null) {
        _showErrorMessage('Please select a customer');
        return;
      }

      if (_selectedItems.isEmpty) {
        _showErrorMessage('Please add at least one item');
        return;
      }

      if (_isEditing && widget.invoice != null) {
        try {
          _invoiceBloc.add(InvoiceUpdateRequested(
            invoiceId: widget.invoice!.id,
            invoiceNumber: _invoiceNumberController.text,
            customerId: _selectedCustomer!.id,
            items: _selectedItems,
            totalAmount: _totalAmount,
            status: _selectedStatus,
          ));
        } catch (e) {
          print('Error updating invoice: $e');
          _showErrorMessage('Failed to update invoice: $e');
          return;
        }
      } else {
        try {
          _invoiceBloc.add(InvoiceCreateRequested(
            customerId: _selectedCustomer!.id,
            invoiceNumber: _invoiceNumberController.text,
            items: _selectedItems,
            totalAmount: _totalAmount,
            status: _selectedStatus,
          ));
        } catch (e) {
          print('Error creating invoice: $e');
          _showErrorMessage('Failed to create invoice: $e');
          return;
        }
      }

      Navigator.pop(context);
    } catch (e) {
      print('Error submitting invoice: $e');
      _showErrorMessage('Failed to save invoice: $e');
    }
  }
}

class _QuantityDialog extends StatefulWidget {
  final StockItem stockItem;
  final Function(int quantity, double price) onItemAdded;

  const _QuantityDialog({
    required this.stockItem,
    required this.onItemAdded,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController(text: widget.stockItem.price.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.stockItem.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity (Available: ${widget.stockItem.quantity})',
                border: const OutlineInputBorder(),
                helperText: 'Enter quantity between 1 and ${widget.stockItem.quantity}',
                errorText: _getQuantityError(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (val) {
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price per unit',
                border: const OutlineInputBorder(),
                helperText: 'Enter price greater than 0',
                errorText: _getPriceError(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid() ? _onAddPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  String? _getQuantityError() {
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0 || quantity > widget.stockItem.quantity) {
      return 'Invalid quantity';
    }
    return null;
  }

  String? _getPriceError() {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      return 'Invalid price';
    }
    return null;
  }

  bool _isValid() {
    final quantity = int.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);
    return quantity != null && 
           quantity > 0 && 
           quantity <= widget.stockItem.quantity && 
           price != null && 
           price > 0;
  }

  void _onAddPressed() {
    final quantity = int.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text);
    
    if (quantity != null && price != null) {
      widget.onItemAdded(quantity, price);
      Navigator.of(context).pop();
    }
  }
}