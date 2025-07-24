import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import 'stock_event.dart';
import 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  StockBloc() : super(StockInitial()) {
    on<StockLoadRequested>(_onStockLoadRequested);
    on<StockAddRequested>(_onStockAddRequested);
    on<StockUpdateRequested>(_onStockUpdateRequested);
    on<StockQuantityUpdateRequested>(_onStockQuantityUpdateRequested);
    on<StockDeleteRequested>(_onStockDeleteRequested);
  }

  Future<void> _onStockLoadRequested(
    StockLoadRequested event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading());
    
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(StockError('User not found'));
        return;
      }

      final response = await ApiService.getStockItems(user.id);
      
      if (response.success && response.data != null) {
        emit(StockLoaded(response.data!));
      } else {
        emit(StockError(response.message));
      }
    } catch (e) {
      emit(StockError('Failed to load stock items: ${e.toString()}'));
    }
  }

  Future<void> _onStockAddRequested(
    StockAddRequested event,
    Emitter<StockState> emit,
  ) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(StockError('User not found'));
        return;
      }

      final response = await ApiService.addStockItem(
        userId: user.id,
        name: event.name,
        price: event.price,
        quantity: event.quantity,
        description: event.description,
        category: event.category,
        sku: event.sku,
      );

      if (response.success) {
        // Reload the stock items
        add(StockLoadRequested());
      } else {
        emit(StockError(response.message));
      }
    } catch (e) {
      emit(StockError('Failed to add stock item: ${e.toString()}'));
    }
  }

  Future<void> _onStockUpdateRequested(
    StockUpdateRequested event,
    Emitter<StockState> emit,
  ) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(StockError('User not found'));
        return;
      }

      final response = await ApiService.updateStockItem(
        userId: user.id,
        itemId: event.itemId,
        name: event.name,
        price: event.price,
        quantity: event.quantity,
        description: event.description,
        category: event.category,
        sku: event.sku,
      );

      if (response.success) {
        // Reload the stock items
        add(StockLoadRequested());
      } else {
        emit(StockError(response.message));
      }
    } catch (e) {
      emit(StockError('Failed to update stock item: ${e.toString()}'));
    }
  }

  Future<void> _onStockQuantityUpdateRequested(
    StockQuantityUpdateRequested event,
    Emitter<StockState> emit,
  ) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(StockError('User not found'));
        return;
      }

      final response = await ApiService.updateStockQuantity(
        userId: user.id,
        itemId: event.itemId,
        quantity: event.quantity,
        operation: event.operation,
      );

      if (response.success) {
        // Reload the stock items
        add(StockLoadRequested());
      } else {
        emit(StockError(response.message));
      }
    } catch (e) {
      emit(StockError('Failed to update stock quantity: ${e.toString()}'));
    }
  }

  Future<void> _onStockDeleteRequested(
    StockDeleteRequested event,
    Emitter<StockState> emit,
  ) async {
    try {
      final user = await StorageService.getUser();
      if (user == null) {
        emit(StockError('User not found'));
        return;
      }

      final response = await ApiService.deleteStockItem(
        userId: user.id,
        itemId: event.itemId,
      );

      if (response.success) {
        // Reload the stock items
        add(StockLoadRequested());
      } else {
        emit(StockError(response.message));
      }
    } catch (e) {
      emit(StockError('Failed to delete stock item: ${e.toString()}'));
    }
  }
}