const express = require('express');
const mongoose = require('mongoose'); // Add this line
const { body, validationResult } = require('express-validator');
const User = require('../models/User');

const router = express.Router();

// CREATE - Add new customer
router.post('/', [
  body('userId').notEmpty().withMessage('User ID is required'),
  body('fullName').notEmpty().withMessage('Full name is required'),
  body('phoneNumber').notEmpty().withMessage('Phone number is required'),
  body('balance').optional().isNumeric().withMessage('Balance must be a number')
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

    const { userId, fullName, phoneNumber, balance = 0 } = req.body;

    // Find user
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if customer with same phone number already exists
    const existingCustomer = user.customers.find(customer => 
      customer.phoneNumber === phoneNumber
    );
    if (existingCustomer) {
      return res.status(400).json({
        success: false,
        message: 'Customer with this phone number already exists'
      });
    }

    // Create new customer
    const newCustomer = {
      fullName,
      phoneNumber,
      balance
    };

    user.customers.push(newCustomer);
    await user.save();

    const createdCustomer = user.customers[user.customers.length - 1];

    res.status(201).json({
      success: true,
      message: 'Customer created successfully',
      data: {
        customer: createdCustomer
      }
    });

  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// READ - Get all customers for a user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log('Received userId:', userId);
    console.log('Is valid ObjectId:', mongoose.Types.ObjectId.isValid(userId));
    
    const user = await User.findById(userId);
    console.log('Found user:', user ? 'Yes' : 'No');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Customers retrieved successfully',
      data: {
        customers: user.customers
      }
    });

  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// READ - Get single customer
router.get('/:userId/:customerId', async (req, res) => {
  try {
    const { userId, customerId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const customer = user.customers.id(customerId);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    res.json({
      success: true,
      message: 'Customer retrieved successfully',
      data: {
        customer: customer
      }
    });

  } catch (error) {
    console.error('Get customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// UPDATE - Update customer
router.put('/:userId/:customerId', [
  body('fullName').optional().notEmpty().withMessage('Full name cannot be empty'),
  body('phoneNumber').optional().notEmpty().withMessage('Phone number cannot be empty'),
  body('balance').optional().isNumeric().withMessage('Balance must be a number')
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

    const { userId, customerId } = req.params;
    const { fullName, phoneNumber, balance } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const customer = user.customers.id(customerId);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    // Check if new phone number already exists (excluding current customer)
    if (phoneNumber && phoneNumber !== customer.phoneNumber) {
      const existingCustomer = user.customers.find(c => 
        c.phoneNumber === phoneNumber && c._id.toString() !== customerId
      );
      if (existingCustomer) {
        return res.status(400).json({
          success: false,
          message: 'Another customer with this phone number already exists'
        });
      }
    }

    // Update customer fields
    if (fullName) customer.fullName = fullName;
    if (phoneNumber) customer.phoneNumber = phoneNumber;
    if (balance !== undefined) customer.balance = balance;

    await user.save();

    res.json({
      success: true,
      message: 'Customer updated successfully',
      data: {
        customer: customer
      }
    });

  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// DELETE - Delete customer
router.delete('/:userId/:customerId', async (req, res) => {
  try {
    const { userId, customerId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const customer = user.customers.id(customerId);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    // Remove customer
    user.customers.pull(customerId);
    await user.save();

    res.json({
      success: true,
      message: 'Customer deleted successfully'
    });

  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

module.exports = router;