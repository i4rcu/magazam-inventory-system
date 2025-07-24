import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:magazam/models/customer.dart';
import 'package:magazam/models/stock_item.dart';
import '../models/user.dart';
import '../models/auth_request.dart';
import '../models/api_response.dart';
import '../models/invoice.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.161:3000/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Register user
  static Future<ApiResponse<User>> register(RegisterRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = User.fromJson(responseData['data'] ?? responseData);
        return ApiResponse<User>(
          success: true,
          message: responseData['message'] ?? 'Registration successful',
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message: responseData['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return const ApiResponse<User>(
        success: false,
        message: 'No internet connection',
      );
    } on HttpException {
      return const ApiResponse<User>(
        success: false,
        message: 'Server error occurred',
      );
    } on FormatException {
      return const ApiResponse<User>(
        success: false,
        message: 'Invalid response format',
      );
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Login user
  static Future<ApiResponse<User>> login(LoginRequest request) async {
    print('$baseUrl/auth/login');
    print(jsonEncode(request.toJson()));
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      print('API Response: $responseData'); // Debug the full API response

      if (response.statusCode == 200) {
        final userData = responseData['data'] ?? responseData;
        print('User data from API: $userData'); // Debug the user data part
        
        final user = User.fromJson(userData);
        print('Created user object: $user'); // Debug the created user
        
        return ApiResponse<User>(
          success: true,
          message: responseData['message'] ?? 'Login successful',
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message: responseData['message'] ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return const ApiResponse<User>(
        success: false,
        message: 'No internet connection',
      );
    } on HttpException {
      return const ApiResponse<User>(
        success: false,
        message: 'Server error occurred',
      );
    } on FormatException {
      return const ApiResponse<User>(
        success: false,
        message: 'Invalid response format',
      );
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  // Facebook Sign-In
  static Future<ApiResponse<User>> loginWithFacebook(String facebookToken) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/facebook'),
            headers: _headers,
            body: jsonEncode({'token': facebookToken}),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = User.fromJson(responseData['data'] ?? responseData);
        return ApiResponse<User>(
          success: true,
          message: responseData['message'] ?? 'Facebook login successful',
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<User>(
          success: false,
          message: responseData['message'] ?? 'Facebook login failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<User>(
        success: false,
        message: 'Facebook login failed: ${e.toString()}',
      );
    }
  }

  // Logout (if you have a logout endpoint)
  static Future<ApiResponse<void>> logout(String token) async {
    try {
      final headers = Map<String, String>.from(_headers);
      headers['Authorization'] = 'Bearer $token';

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: headers,
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: responseData['message'] ?? 'Logout successful',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: responseData['message'] ?? 'Logout failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Logout failed: ${e.toString()}',
      );
    }
  }

  // Get all customers
  static Future<ApiResponse<List<Customer>>> getCustomers(String userId) async {

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/customers/$userId'),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> customersData = responseData['data']['customers'] ?? [];
        final List<Customer> customers = customersData
            .map((customerJson) => Customer.fromJson(customerJson))
            .toList();

        return ApiResponse<List<Customer>>(
          success: true,
          message: responseData['message'] ?? 'Customers loaded successfully',
          data: customers,
          statusCode: response.statusCode,
        );
      } else {

        return ApiResponse<List<Customer>>(
          success: false,
          message: responseData['message'] ?? 'Failed to load customers',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Customer>>(
        success: false,
        message: 'Failed to load customers: ${e.toString()}',
      );
    }
  }

  // Add new customer
  static Future<ApiResponse<Customer>> addCustomer({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required double balance,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/customers'),
            headers: _headers,
            body: jsonEncode({
              'userId': userId,
              'fullName': fullName,
              'phoneNumber': phoneNumber,
              'balance': balance,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final customer = Customer.fromJson(responseData['data']['customer']);
        return ApiResponse<Customer>(
          success: true,
          message: responseData['message'] ?? 'Customer added successfully',
          data: customer,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Customer>(
          success: false,
          message: responseData['message'] ?? 'Failed to add customer',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Customer>(
        success: false,
        message: 'Failed to add customer: ${e.toString()}',
      );
    }
  }

  // Update customer
  static Future<ApiResponse<Customer>> updateCustomer({
    required String userId,
    required String customerId,
    required String fullName,
    required String phoneNumber,
    required double balance,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/customers/$userId/$customerId'),
            headers: _headers,
            body: jsonEncode({
              'fullName': fullName,
              'phoneNumber': phoneNumber,
              'balance': balance,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final customer = Customer.fromJson(responseData['data']['customer']);
        return ApiResponse<Customer>(
          success: true,
          message: responseData['message'] ?? 'Customer updated successfully',
          data: customer,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Customer>(
          success: false,
          message: responseData['message'] ?? 'Failed to update customer',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Customer>(
        success: false,
        message: 'Failed to update customer: ${e.toString()}',
      );
    }
  }

  // Delete customer
  static Future<ApiResponse<void>> deleteCustomer({
    required String userId,
    required String customerId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/customers/$userId/$customerId'),
            headers: _headers,
            body: jsonEncode({'userId': userId}),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: responseData['message'] ?? 'Customer deleted successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: responseData['message'] ?? 'Failed to delete customer',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Failed to delete customer: ${e.toString()}',
      );
    }
  }

  // Get all stock items
  static Future<ApiResponse<List<StockItem>>> getStockItems(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/stock/$userId'),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> stockItemsData = responseData['data']['stockItems'] ?? [];
        final List<StockItem> stockItems = stockItemsData
            .map((itemJson) => StockItem.fromJson(itemJson))
            .toList();

        return ApiResponse<List<StockItem>>(
          success: true,
          message: responseData['message'] ?? 'Stock items loaded successfully',
          data: stockItems,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<StockItem>>(
          success: false,
          message: responseData['message'] ?? 'Failed to load stock items',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<StockItem>>(
        success: false,
        message: 'Failed to load stock items: ${e.toString()}',
      );
    }
  }

  // Add new stock item
  static Future<ApiResponse<StockItem>> addStockItem({
    required String userId,
    required String name,
    required double price,
    required int quantity,
    String? description,
    String? category,
    String? sku,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/stock'),
            headers: _headers,
            body: jsonEncode({
              'userId': userId,
              'name': name,
              'price': price,
              'quantity': quantity,
              'description': description,
              'category': category,
              'sku': sku,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final stockItem = StockItem.fromJson(responseData['data']['stockItem']);
        return ApiResponse<StockItem>(
          success: true,
          message: responseData['message'] ?? 'Stock item added successfully',
          data: stockItem,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<StockItem>(
          success: false,
          message: responseData['message'] ?? 'Failed to add stock item',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<StockItem>(
        success: false,
        message: 'Failed to add stock item: ${e.toString()}',
      );
    }
  }

  // Update stock item
  static Future<ApiResponse<StockItem>> updateStockItem({
    required String userId,
    required String itemId,
    required String name,
    required double price,
    required int quantity,
    String? description,
    String? category,
    String? sku,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/stock/$userId/$itemId'),
            headers: _headers,
            body: jsonEncode({
              'name': name,
              'price': price,
              'quantity': quantity,
              'description': description,
              'category': category,
              'sku': sku,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final stockItem = StockItem.fromJson(responseData['data']['stockItem']);
        return ApiResponse<StockItem>(
          success: true,
          message: responseData['message'] ?? 'Stock item updated successfully',
          data: stockItem,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<StockItem>(
          success: false,
          message: responseData['message'] ?? 'Failed to update stock item',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<StockItem>(
        success: false,
        message: 'Failed to update stock item: ${e.toString()}',
      );
    }
  }

  // Update stock quantity
  static Future<ApiResponse<StockItem>> updateStockQuantity({
    required String userId,
    required String itemId,
    required int quantity,
    String operation = 'set', // 'set', 'add', 'subtract'
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/stock/$userId/$itemId/quantity'),
            headers: _headers,
            body: jsonEncode({
              'quantity': quantity,
              'operation': operation,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final stockItem = StockItem.fromJson(responseData['data']['stockItem']);
        return ApiResponse<StockItem>(
          success: true,
          message: responseData['message'] ?? 'Stock quantity updated successfully',
          data: stockItem,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<StockItem>(
          success: false,
          message: responseData['message'] ?? 'Failed to update stock quantity',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<StockItem>(
        success: false,
        message: 'Failed to update stock quantity: ${e.toString()}',
      );
    }
  }

  // Delete stock item
  static Future<ApiResponse<void>> deleteStockItem({
    required String userId,
    required String itemId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/stock/$userId/$itemId'),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: responseData['message'] ?? 'Stock item deleted successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: responseData['message'] ?? 'Failed to delete stock item',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Failed to delete stock item: ${e.toString()}',
      );
    }
  }

  // Get all invoices
  static Future<ApiResponse<List<Invoice>>> getInvoices(
    String userId, {
    String? status,
    String? customerId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (customerId != null) queryParams['customerId'] = customerId;

      final uri = Uri.parse('$baseUrl/invoices/$userId').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http
          .get(uri, headers: _headers)
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> invoicesData = responseData['data']['invoices'] ?? [];
        final List<Invoice> invoices = invoicesData
            .map((invoiceJson) => Invoice.fromJson(invoiceJson))
            .toList();

        return ApiResponse<List<Invoice>>(
          success: true,
          message: responseData['message'] ?? 'Invoices loaded successfully',
          data: invoices,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<List<Invoice>>(
          success: false,
          message: responseData['message'] ?? 'Failed to load invoices',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<List<Invoice>>(
        success: false,
        message: 'Failed to load invoices: ${e.toString()}',
      );
    }
  }

  // Get single invoice
  static Future<ApiResponse<Map<String, dynamic>>> getInvoice(
    String userId,
    String invoiceId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/invoices/$userId/$invoiceId'),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: responseData['message'] ?? 'Invoice loaded successfully',
          data: responseData['data'],
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: responseData['message'] ?? 'Failed to load invoice',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Failed to load invoice: ${e.toString()}',
      );
    }
  }

  // Create new invoice
  static Future<ApiResponse<Invoice>> createInvoice({
    required String userId,
    required String customerId,
    required String invoiceNumber,
    required List<InvoiceItem> items,
    required double totalAmount,
    InvoiceStatus status = InvoiceStatus.pending,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/invoices'),
            headers: _headers,
            body: jsonEncode({
              'userId': userId,
              'customerId': customerId,
              'invoiceNumber': invoiceNumber,
              'items': items.map((item) => item.toJson()).toList(),
              'totalAmount': totalAmount,
              'status': status.name,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final invoice = Invoice.fromJson(responseData['data']['invoice']);
        return ApiResponse<Invoice>(
          success: true,
          message: responseData['message'] ?? 'Invoice created successfully',
          data: invoice,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Invoice>(
          success: false,
          message: responseData['message'] ?? 'Failed to create invoice',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Invoice>(
        success: false,
        message: 'Failed to create invoice: ${e.toString()}',
      );
    }
  }

  // Update invoice
  static Future<ApiResponse<Invoice>> updateInvoice({
    required String userId,
    required String invoiceId,
    String? invoiceNumber,
    String? customerId,
    List<InvoiceItem>? items,
    double? totalAmount,
    InvoiceStatus? status,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {};
      if (invoiceNumber != null) requestBody['invoiceNumber'] = invoiceNumber;
      if (customerId != null) requestBody['customerId'] = customerId;
      if (items != null) requestBody['items'] = items.map((item) => item.toJson()).toList();
      if (totalAmount != null) requestBody['totalAmount'] = totalAmount;
      if (status != null) requestBody['status'] = status.name;

      final response = await http
          .put(
            Uri.parse('$baseUrl/invoices/$userId/$invoiceId'),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final invoice = Invoice.fromJson(responseData['data']['invoice']);
        return ApiResponse<Invoice>(
          success: true,
          message: responseData['message'] ?? 'Invoice updated successfully',
          data: invoice,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Invoice>(
          success: false,
          message: responseData['message'] ?? 'Failed to update invoice',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Invoice>(
        success: false,
        message: 'Failed to update invoice: ${e.toString()}',
      );
    }
  }

  // Update invoice status
  static Future<ApiResponse<Invoice>> updateInvoiceStatus({
    required String userId,
    required String invoiceId,
    required InvoiceStatus status,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/invoices/$userId/$invoiceId/status'),
            headers: _headers,
            body: jsonEncode({
              'status': status.name,
            }),
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final invoice = Invoice.fromJson(responseData['data']['invoice']);
        return ApiResponse<Invoice>(
          success: true,
          message: responseData['message'] ?? 'Invoice status updated successfully',
          data: invoice,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Invoice>(
          success: false,
          message: responseData['message'] ?? 'Failed to update invoice status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<Invoice>(
        success: false,
        message: 'Failed to update invoice status: ${e.toString()}',
      );
    }
  }

  // Delete invoice
  static Future<ApiResponse<void>> deleteInvoice({
    required String userId,
    required String invoiceId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/invoices/$userId/$invoiceId'),
            headers: _headers,
          )
          .timeout(timeoutDuration);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: responseData['message'] ?? 'Invoice deleted successfully',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: responseData['message'] ?? 'Failed to delete invoice',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'Failed to delete invoice: ${e.toString()}',
      );
    }
  }
}
