abstract class StockEvent {}

class StockLoadRequested extends StockEvent {}

class StockAddRequested extends StockEvent {
  final String name;
  final double price;
  final int quantity;
  final String? description;
  final String? category;
  final String? sku;

  StockAddRequested({
    required this.name,
    required this.price,
    required this.quantity,
    this.description,
    this.category,
    this.sku,
  });
}

class StockUpdateRequested extends StockEvent {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String? description;
  final String? category;
  final String? sku;

  StockUpdateRequested({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.description,
    this.category,
    this.sku,
  });
}

class StockQuantityUpdateRequested extends StockEvent {
  final String itemId;
  final int quantity;
  final String operation;

  StockQuantityUpdateRequested({
    required this.itemId,
    required this.quantity,
    required this.operation,
  });
}

class StockDeleteRequested extends StockEvent {
  final String itemId;

  StockDeleteRequested(this.itemId);
}