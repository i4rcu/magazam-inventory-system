import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'invoice_event.dart';
import 'invoice_state.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  InvoiceBloc() : super(InvoiceInitial()) {
    on<InvoiceLoadRequested>(_onInvoiceLoadRequested);
    on<InvoiceCreateRequested>(_onInvoiceCreateRequested);
    on<InvoiceUpdateRequested>(_onInvoiceUpdateRequested);
    on<InvoiceStatusUpdateRequested>(_onInvoiceStatusUpdateRequested);
    on<InvoiceDeleteRequested>(_onInvoiceDeleteRequested);
  }

  Future<void> _onInvoiceLoadRequested(
    InvoiceLoadRequested event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(InvoiceError('User not found'));
        return;
      }

      final response = await ApiService.getInvoices(
        user.id,
        status: event.status,
        customerId: event.customerId,
      );
      
      if (response.success && response.data != null) {
        emit(InvoiceLoaded(response.data!));
      } else {
        emit(InvoiceError(response.message));
      }
    } catch (e) {
      emit(InvoiceError('Failed to load invoices: ${e.toString()}'));
    }
  }

  Future<void> _onInvoiceCreateRequested(
    InvoiceCreateRequested event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(InvoiceError('User not found'));
        return;
      }

      final response = await ApiService.createInvoice(
        userId: user.id,
        customerId: event.customerId,
        invoiceNumber: event.invoiceNumber,
        items: event.items,
        totalAmount: event.totalAmount,
        status: event.status,
      );

      if (response.success) {
        // Reload the invoices
        add(InvoiceLoadRequested());
      } else {
        emit(InvoiceError(response.message));
      }
    } catch (e) {
      emit(InvoiceError('Failed to create invoice: ${e.toString()}'));
    }
  }

  Future<void> _onInvoiceUpdateRequested(
    InvoiceUpdateRequested event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(InvoiceError('User not found'));
        return;
      }

      final response = await ApiService.updateInvoice(
        userId: user.id,
        invoiceId: event.invoiceId,
        invoiceNumber: event.invoiceNumber,
        customerId: event.customerId,
        items: event.items,
        totalAmount: event.totalAmount,
        status: event.status,
      );

      if (response.success) {
        // Reload the invoices
        add(InvoiceLoadRequested());
      } else {
        emit(InvoiceError(response.message));
      }
    } catch (e) {
      emit(InvoiceError('Failed to update invoice: ${e.toString()}'));
    }
  }

  Future<void> _onInvoiceStatusUpdateRequested(
    InvoiceStatusUpdateRequested event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(InvoiceError('User not found'));
        return;
      }

      final response = await ApiService.updateInvoiceStatus(
        userId: user.id,
        invoiceId: event.invoiceId,
        status: event.status,
      );

      if (response.success) {
        // Reload the invoices
        add(InvoiceLoadRequested());
      } else {
        emit(InvoiceError(response.message));
      }
    } catch (e) {
      emit(InvoiceError('Failed to update invoice status: ${e.toString()}'));
    }
  }

  Future<void> _onInvoiceDeleteRequested(
    InvoiceDeleteRequested event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(InvoiceError('User not found'));
        return;
      }

      final response = await ApiService.deleteInvoice(
        userId: user.id,
        invoiceId: event.invoiceId,
      );

      if (response.success) {
        // Reload the invoices
        add(InvoiceLoadRequested());
      } else {
        emit(InvoiceError(response.message));
      }
    } catch (e) {
      emit(InvoiceError('Failed to delete invoice: ${e.toString()}'));
    }
  }
}