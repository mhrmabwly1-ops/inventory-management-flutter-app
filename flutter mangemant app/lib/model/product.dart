// lib/models/product.dart

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final String? category;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    this.category,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'] is int ? (map['price'] as int).toDouble() : map['price'],
      quantity: map['quantity'],
      category: map['category'],
      imageUrl: map['imageUrl'],
    );
  }
}