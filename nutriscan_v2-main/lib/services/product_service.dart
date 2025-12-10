import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer un produit (Firestore ou Open Food Facts)
  Future<Product?> fetchProduct(String barcode) async {
    try {
      // Vérifier dans Firestore
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(barcode).get();
      if (doc.exists) {
        return Product.fromFirestore(doc.data() as Map<String, dynamic>);
      }

      // Si non trouvé, consulter Open Food Facts
      return await _fetchFromOpenFoodFacts(barcode);
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Récupérer depuis Open Food Facts
  Future<Product?> _fetchFromOpenFoodFacts(String barcode) async {
    try {
      final url =
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final productData = data['product'];
          return Product(
            productName: productData['product_name'] ?? 'Unknown',
            brands: productData['brands'] ?? 'N/A',
            ingredientsText: productData['ingredients_text'] ?? 'N/A',
            allergens: productData['allergens'] ?? 'N/A',
            imageUrl: productData['image_url'] ?? '',
            energy: double.tryParse(
              productData['nutriments']['energy-kcal_100g']?.toString() ?? '0',
            ),
            fat: double.tryParse(
              productData['nutriments']['fat_100g']?.toString() ?? '0',
            ),
            sugar: double.tryParse(
              productData['nutriments']['sugars_100g']?.toString() ?? '0',
            ),
            salt: double.tryParse(
              productData['nutriments']['salt_100g']?.toString() ?? '0',
            ),
            protein: double.tryParse(
              productData['nutriments']['proteins_100g']?.toString() ?? '0',
            ),
            nutriScore: productData['nutriscore_grade']?.toString() ?? 'N/A',
            novaGroup: productData['nova_group']?.toString() ?? 'N/A',
            ecoScore: productData['ecoscore_grade']?.toString() ?? 'N/A',
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching from Open Food Facts: $e');
    }
  }

  // Ajouter un produit à Firestore
  Future<String?> addProduct(Product product, String barcode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'User not authenticated';
      }
      await _firestore.collection('products').doc(barcode).set({
        'productName': product.productName,
        'brands': product.brands,
        'ingredientsText': product.ingredientsText,
        'allergens': product.allergens,
        'imageUrl': product.imageUrl,
        'energy': product.energy,
        'fat': product.fat,
        'sugar': product.sugar,
        'salt': product.salt,
        'protein': product.protein,
        'nutriScore': product.nutriScore,
        'novaGroup': product.novaGroup,
        'ecoScore': product.ecoScore,
        'addedBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Error adding product: $e';
    }
  }

  // Mettre à jour un produit
  Future<String?> updateProduct(Product product, String barcode) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'User not authenticated';
      }
      await _firestore.collection('products').doc(barcode).update({
        'productName': product.productName,
        'brands': product.brands,
        'ingredientsText': product.ingredientsText,
        'allergens': product.allergens,
        'imageUrl': product.imageUrl,
        'energy': product.energy,
        'fat': product.fat,
        'sugar': product.sugar,
        'salt': product.salt,
        'protein': product.protein,
        'nutriScore': product.nutriScore,
        'novaGroup': product.novaGroup,
        'ecoScore': product.ecoScore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return 'Error updating product: $e';
    }
  }

  // Supprimer un produit
  Future<String?> deleteProduct(String barcode) async {
    try {
      await _firestore.collection('products').doc(barcode).delete();
      return null;
    } catch (e) {
      return 'Error deleting product: $e';
    }
  }
}
