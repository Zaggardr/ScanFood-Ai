import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductFirestoreService {
  final CollectionReference _productsCollection = FirebaseFirestore.instance
      .collection('products');

  // Ajouter ou mettre à jour un produit
  Future<void> addProduct({
    required String barcode,
    required String productName,
    String? brands,
    String? ingredientsText,
    String? allergens,
    String? imageUrl,
    String? nutriScore,
    String? novaGroup,
    String? ecoScore,
    double? energy,
    double? fat,
    double? sugar,
    double? salt,
    double? protein,
  }) async {
    try {
      await _productsCollection.doc(barcode).set({
        'barcode': barcode,
        'productName': productName,
        'brands': brands ?? 'N/A',
        'ingredientsText': ingredientsText ?? 'N/A',
        'allergens': allergens ?? 'N/A',
        'imageUrl': imageUrl ?? '',
        'nutriScore': nutriScore ?? 'N/A',
        'novaGroup': novaGroup ?? 'N/A',
        'ecoScore': ecoScore ?? 'N/A',
        'energy': energy ?? 0.0,
        'fat': fat ?? 0.0,
        'sugar': sugar ?? 0.0,
        'salt': salt ?? 0.0,
        'protein': protein ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Product added/updated: $barcode');
    } catch (e) {
      print('Error adding product: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  // Récupérer un produit par code-barres
  Future<Product?> getProduct(String barcode) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(barcode).get();
      if (doc.exists) {
        return Product.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      print('Product not found in Firestore: $barcode');
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }
}
