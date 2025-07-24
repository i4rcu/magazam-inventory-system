const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');

const router = express.Router();

// CREATE - Add new stock item
router.post('/', [
  body('userId').notEmpty().withMessage('User ID is required'),
  body('name').notEmpty().withMessage('Item name is required'),
  body('price').isNumeric().withMessage('Price must be a number'),
  body('quantity').isNumeric().withMessage('Quantity must be a number'),
  body('description').optional().isString(),
  body('category').optional().isString(),
  body('sku').optional().isString()
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

    const { userId, name, price, quantity, description, category, sku } = req.body;

    // Find user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if item with same SKU already exists (if SKU is provided)
    if (sku) {
      const existingItem = user.stockItems.find(item => item.sku === sku);
      if (existingItem) {
        return res.status(400).json({
          success: false,
          message: 'Item with this SKU already exists'
        });
      }
    }

    // Create new stock item
    const newStockItem = {
      name,
      price,
      quantity,
      description,
      category,
      sku
    };

    user.stockItems.push(newStockItem);
    await user.save();

    const createdItem = user.stockItems[user.stockItems.length - 1];

    res.status(201).json({
      success: true,
      message: 'Stock item created successfully',
      data: {
        stockItem: createdItem
      }
    });

  } catch (error) {
    console.error('Create stock item error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// READ - Get all stock items for a user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Stock items retrieved successfully',
      data: {
        stockItems: user.stockItems
      }
    });

  } catch (error) {
    console.error('Get stock items error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// READ - Get single stock item
router.get('/:userId/:itemId', async (req, res) => {
  try {
    const { userId, itemId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const stockItem = user.stockItems.id(itemId);
    if (!stockItem) {
      return res.status(404).json({
        success: false,
        message: 'Stock item not found'
      });
    }

    res.json({
      success: true,
      message: 'Stock item retrieved successfully',
      data: {
        stockItem: stockItem
      }
    });

  } catch (error) {
    console.error('Get stock item error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// UPDATE - Update stock item
router.put('/:userId/:itemId', [
  body('name').optional().notEmpty().withMessage('Item name cannot be empty'),
  body('price').optional().isNumeric().withMessage('Price must be a number'),
  body('quantity').optional().isNumeric().withMessage('Quantity must be a number'),
  body('description').optional().isString(),
  body('category').optional().isString(),
  body('sku').optional().isString()
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

    const { userId, itemId } = req.params;
    const { name, price, quantity, description, category, sku } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const stockItem = user.stockItems.id(itemId);
    if (!stockItem) {
      return res.status(404).json({
        success: false,
        message: 'Stock item not found'
      });
    }

    // Check if new SKU already exists (excluding current item)
    if (sku && sku !== stockItem.sku) {
      const existingItem = user.stockItems.find(item => 
        item.sku === sku && item._id.toString() !== itemId
      );
      if (existingItem) {
        return res.status(400).json({
          success: false,
          message: 'Another item with this SKU already exists'
        });
      }
    }

    // Update stock item fields
    if (name) stockItem.name = name;
    if (price !== undefined) stockItem.price = price;
    if (quantity !== undefined) stockItem.quantity = quantity;
    if (description !== undefined) stockItem.description = description;
    if (category !== undefined) stockItem.category = category;
    if (sku !== undefined) stockItem.sku = sku;

    await user.save();

    res.json({
      success: true,
      message: 'Stock item updated successfully',
      data: {
        stockItem: stockItem
      }
    });

  } catch (error) {
    console.error('Update stock item error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// UPDATE QUANTITY - Special endpoint to update only quantity
router.patch('/:userId/:itemId/quantity', [
  body('quantity').isNumeric().withMessage('Quantity must be a number'),
  body('operation').optional().isIn(['set', 'add', 'subtract']).withMessage('Operation must be set, add, or subtract')
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

    const { userId, itemId } = req.params;
    const { quantity, operation = 'set' } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const stockItem = user.stockItems.id(itemId);
    if (!stockItem) {
      return res.status(404).json({
        success: false,
        message: 'Stock item not found'
      });
    }

    // Update quantity based on operation
    let newQuantity;
    switch (operation) {
      case 'add':
        newQuantity = stockItem.quantity + quantity;
        break;
      case 'subtract':
        newQuantity = stockItem.quantity - quantity;
        break;
      case 'set':
      default:
        newQuantity = quantity;
        break;
    }

    // Ensure quantity doesn't go below 0
    if (newQuantity < 0) {
      return res.status(400).json({
        success: false,
        message: 'Quantity cannot be negative'
      });
    }

    stockItem.quantity = newQuantity;
    await user.save();

    res.json({
      success: true,
      message: 'Stock quantity updated successfully',
      data: {
        stockItem: stockItem,
        previousQuantity: operation === 'set' ? null : (operation === 'add' ? stockItem.quantity - quantity : stockItem.quantity + quantity),
        operation: operation
      }
    });

  } catch (error) {
    console.error('Update quantity error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// DELETE - Delete stock item
router.delete('/:userId/:itemId', async (req, res) => {
  try {
    const { userId, itemId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const stockItem = user.stockItems.id(itemId);
    if (!stockItem) {
      return res.status(404).json({
        success: false,
        message: 'Stock item not found'
      });
    }

    // Remove stock item
    user.stockItems.pull(itemId);
    await user.save();

    res.json({
      success: true,
      message: 'Stock item deleted successfully'
    });

  } catch (error) {
    console.error('Delete stock item error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;