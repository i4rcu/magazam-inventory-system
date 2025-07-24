class StockItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? description;
  final String? category;
  final String? sku;

  StockItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.description,
    this.category,
    this.sku,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      sku: json['sku']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'description': description,
      'category': category,
      'sku': sku,
    };
  }

  StockItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? description,
    String? category,
    String? sku,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      category: category ?? this.category,
      sku: sku ?? this.sku,
    );
  }
}