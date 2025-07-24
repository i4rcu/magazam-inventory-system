const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');

const router = express.Router();

// CREATE - Add new invoice
router.post('/', [
  body('userId').notEmpty().withMessage('User ID is required'),
  body('customerId').notEmpty().withMessage('Customer ID is required'),
  body('invoiceNumber').notEmpty().withMessage('Invoice number is required'),
  body('items').isArray({ min: 1 }).withMessage('Items must be an array with at least one item'),
  body('items.*.itemId').notEmpty().withMessage('Item ID is required for each item'),
  body('items.*.name').notEmpty().withMessage('Item name is required for each item'),
  body('items.*.quantity').isNumeric().withMessage('Quantity must be a number'),
  body('items.*.price').isNumeric().withMessage('Price must be a number'),
  body('totalAmount').isNumeric().withMessage('Total amount must be a number'),
  body('status').optional().isIn(['pending', 'paid', 'cancelled']).withMessage('Status must be pending, paid, or cancelled')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { userId, customerId, invoiceNumber, items, totalAmount, status = 'pending' } = req.body;

    // Find user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Verify customer exists
    const customer = user.customers.id(customerId);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    // Check if invoice number already exists
    const existingInvoice = user.invoices.find(invoice => 
      invoice.invoiceNumber === invoiceNumber
    );
    if (existingInvoice) {
      return res.status(400).json({
        success: false,
        message: 'Invoice with this number already exists'
      });
    }

    // Verify all items exist in stock and have sufficient quantity
    for (const item of items) {
      const stockItem = user.stockItems.id(item.itemId);
      if (!stockItem) {
        return res.status(404).json({
          success: false,
          message: `Stock item with ID ${item.itemId} not found`
        });
      }
      if (stockItem.quantity < item.quantity) {
        return res.status(400).json({
          success: false,
          message: `Insufficient stock for item ${stockItem.name}. Available: ${stockItem.quantity}, Required: ${item.quantity}`
        });
      }
    }

    // Create new invoice
    const newInvoice = {
      invoiceNumber,
      customerId,
      items,
      totalAmount,
      status
    };

    user.invoices.push(newInvoice);

    // Update stock quantities
    for (const item of items) {
      const stockItem = user.stockItems.id(item.itemId);
      stockItem.quantity -= item.quantity;
    }

    // Update customer balance based on invoice status
    if (status === 'pending') {
      // Add to customer's debt (increase balance)
      customer.balance += totalAmount;
    } else if (status === 'paid') {
      // Invoice is paid, no change to balance
      // Balance remains the same
    } else if (status === 'cancelled') {
      // Cancelled invoice, no change to balance
      // Balance remains the same
    }

    await user.save();

    const createdInvoice = user.invoices[user.invoices.length - 1];

    res.status(201).json({
      success: true,
      message: 'Invoice created successfully',
      data: {
        invoice: createdInvoice,
        customerBalance: customer.balance
      }
    });

  } catch (error) {
    console.error('Create invoice error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// READ - Get all invoices for a user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { status, customerId } = req.query;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    let invoices = user.invoices;

    // Filter by status if provided
    if (status) {
      invoices = invoices.filter(invoice => invoice.status === status);
    }

    // Filter by customer if provided
    if (customerId) {
      invoices = invoices.filter(invoice => invoice.customerId.toString() === customerId);
    }

    res.json({
      success: true,
      message: 'Invoices retrieved successfully',
      data: {
        invoices: invoices
      }
    });

  } catch (error) {
    console.error('Get invoices error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// READ - Get single invoice
router.get('/:userId/:invoiceId', async (req, res) => {
  try {
    const { userId, invoiceId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const invoice = user.invoices.id(invoiceId);
    if (!invoice) {
      return res.status(404).json({
        success: false,
        message: 'Invoice not found'
      });
    }

    // Get customer details
    const customer = user.customers.id(invoice.customerId);

    res.json({
      success: true,
      message: 'Invoice retrieved successfully',
      data: {
        invoice: invoice,
        customer: customer
      }
    });

  } catch (error) {
    console.error('Get invoice error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// UPDATE - Update invoice
router.put('/:userId/:invoiceId', [
  body('invoiceNumber').optional().notEmpty().withMessage('Invoice number cannot be empty'),
  body('customerId').optional().notEmpty().withMessage('Customer ID cannot be empty'),
  body('items').optional().isArray({ min: 1 }).withMessage('Items must be an array with at least one item'),
  body('items.*.itemId').optional().notEmpty().withMessage('Item ID is required for each item'),
  body('items.*.name').optional().notEmpty().withMessage('Item name is required for each item'),
  body('items.*.quantity').optional().isNumeric().withMessage('Quantity must be a number'),
  body('items.*.price').optional().isNumeric().withMessage('Price must be a number'),
  body('totalAmount').optional().isNumeric().withMessage('Total amount must be a number'),
  body('status').optional().isIn(['pending', 'paid', 'cancelled']).withMessage('Status must be pending, paid, or cancelled')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { userId, invoiceId } = req.params;
    const { invoiceNumber, customerId, items, totalAmount, status } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const invoice = user.invoices.id(invoiceId);
    if (!invoice) {
      return res.status(404).json({
        success: false,
        message: 'Invoice not found'
      });
    }

    // Check if new invoice number already exists (excluding current invoice)
    if (invoiceNumber && invoiceNumber !== invoice.invoiceNumber) {
      const existingInvoice = user.invoices.find(inv => 
        inv.invoiceNumber === invoiceNumber && inv._id.toString() !== invoiceId
      );
      if (existingInvoice) {
        return res.status(400).json({
          success: false,
          message: 'Another invoice with this number already exists'
        });
      }
    }

    // Verify customer exists if customerId is being updated
    if (customerId && customerId !== invoice.customerId.toString()) {
      const customer = user.customers.id(customerId);
      if (!customer) {
        return res.status(404).json({
          success: false,
          message: 'Customer not found'
        });
      }
    }

    // Update invoice fields
    if (invoiceNumber) invoice.invoiceNumber = invoiceNumber;
    if (customerId) invoice.customerId = customerId;
    if (items) invoice.items = items;
    if (totalAmount !== undefined) invoice.totalAmount = totalAmount;
    if (status) invoice.status = status;

    await user.save();

    res.json({
      success: true,
      message: 'Invoice updated successfully',
      data: {
        invoice: invoice
      }
    });

  } catch (error) {
    console.error('Update invoice error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// UPDATE STATUS - Update invoice status only
router.patch('/:userId/:invoiceId/status', [
  body('status').isIn(['pending', 'paid', 'cancelled']).withMessage('Status must be pending, paid, or cancelled')
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    const { userId, invoiceId } = req.params;
    const { status } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const invoice = user.invoices.id(invoiceId);
    if (!invoice) {
      return res.status(404).json({
        success: false,
        message: 'Invoice not found'
      });
    }

    // Get customer
    const customer = user.customers.id(invoice.customerId);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const previousStatus = invoice.status;
    const invoiceAmount = invoice.totalAmount;

    // Update customer balance based on status change
    if (previousStatus === 'pending' && status === 'paid') {
      // Customer paid the debt, reduce balance
      customer.balance -= invoiceAmount;
    } else if (previousStatus === 'pending' && status === 'cancelled') {
      // Invoice cancelled, remove from debt
      customer.balance -= invoiceAmount;
    } else if (previousStatus === 'paid' && status === 'pending') {
      // Payment reversed, add back to debt
      customer.balance += invoiceAmount;
    } else if (previousStatus === 'cancelled' && status === 'pending') {
      // Reactivate invoice, add to debt
      customer.balance += invoiceAmount;
    }
    // No balance change for: paid -> cancelled, cancelled -> paid

    invoice.status = status;
    await user.save();

    res.json({
      success: true,
      message: 'Invoice status updated successfully',
      data: {
        invoice: invoice,
        previousStatus: previousStatus,
        customerBalance: customer.balance
      }
    });

  } catch (error) {
    console.error('Update invoice status error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// DELETE - Delete invoice
router.delete('/:userId/:invoiceId', async (req, res) => {
  try {
    const { userId, invoiceId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const invoice = user.invoices.id(invoiceId);
    if (!invoice) {
      return res.status(404).json({
        success: false,
        message: 'Invoice not found'
      });
    }

    // Get customer
    const customer = user.customers.id(invoice.customerId);
    if (customer) {
      // If invoice was pending, remove from customer's debt
      if (invoice.status === 'pending') {
        customer.balance -= invoice.totalAmount;
      }
    }

    // Restore stock quantities if invoice is being deleted
    for (const item of invoice.items) {
      const stockItem = user.stockItems.id(item.itemId);
      if (stockItem) {
        stockItem.quantity += item.quantity;
      }
    }

    // Remove invoice
    user.invoices.pull(invoiceId);
    await user.save();

    res.json({
      success: true,
      message: 'Invoice deleted successfully',
      customerBalance: customer ? customer.balance : null
    });

  } catch (error) {
    console.error('Delete invoice error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;