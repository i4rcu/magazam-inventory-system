import '../../models/stock_item.dart';

abstract class StockState {}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<StockItem> stockItems;

  StockLoaded(this.stockItems);
}

class StockError extends StockState {
  final String message;

  StockError(this.message);
}