import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc() : super(CustomerInitial()) {
    on<CustomerLoadRequested>(_onCustomerLoadRequested);
    on<CustomerAddRequested>(_onCustomerAddRequested);
    on<CustomerUpdateRequested>(_onCustomerUpdateRequested);
    on<CustomerDeleteRequested>(_onCustomerDeleteRequested);
  }

  Future<void> _onCustomerLoadRequested(
    CustomerLoadRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(CustomerError('User not found'));
        return;
      }

      final response = await ApiService.getCustomers(user.id);
      
      if (response.success && response.data != null) {
        emit(CustomerLoaded(response.data!));
      } else {
        emit(CustomerError(response.message ?? 'Failed to load customers'));
      }
    } catch (e) {
      emit(CustomerError('Failed to load customers: ${e.toString()}'));
    }
  }

  Future<void> _onCustomerAddRequested(
    CustomerAddRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(CustomerError('User not found'));
        return;
      }

      final response = await ApiService.addCustomer(
        userId: user.id,
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
        balance: event.balance,
      );
      
      if (response.success) {
        // Reload customers after successful add
        add(CustomerLoadRequested());
      } else {
        emit(CustomerError(response.message ?? 'Failed to add customer'));
      }
    } catch (e) {
      emit(CustomerError('Failed to add customer: ${e.toString()}'));
    }
  }

  Future<void> _onCustomerUpdateRequested(
    CustomerUpdateRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(CustomerError('User not found'));
        return;
      }

      final response = await ApiService.updateCustomer(
        userId: user.id,
        customerId: event.customerId,
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
        balance: event.balance,
      );
      
      if (response.success) {
        // Reload customers after successful update
        add(CustomerLoadRequested());
      } else {
        emit(CustomerError(response.message ?? 'Failed to update customer'));
      }
    } catch (e) {
      emit(CustomerError('Failed to update customer: ${e.toString()}'));
    }
  }

  Future<void> _onCustomerDeleteRequested(
    CustomerDeleteRequested event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(CustomerError('User not found'));
        return;
      }

      final response = await ApiService.deleteCustomer(
        userId: user.id,
        customerId: event.customerId,
      );
      
      if (response.success) {
        // Reload customers after successful delete
        add(CustomerLoadRequested());
      } else {
        emit(CustomerError(response.message ?? 'Failed to delete customer'));
      }
    } catch (e) {
      emit(CustomerError('Failed to delete customer: ${e.toString()}'));
    }
  }
}