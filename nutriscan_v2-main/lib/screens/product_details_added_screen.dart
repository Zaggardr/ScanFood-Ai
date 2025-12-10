import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductDetailsAddedScreen extends StatefulWidget {
  @override
  _ProductDetailsAddedScreenState createState() =>
      _ProductDetailsAddedScreenState();
}

class _ProductDetailsAddedScreenState extends State<ProductDetailsAddedScreen> {
  final ProductService _productService = ProductService();
  final _formKey = GlobalKey<FormState>();
  late Product _product;
  late String _productId;
  bool _isEditing = false;
  bool _isLoading = false;

  // Contrôleurs pour les champs modifiables
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _ingredientsController;
  late TextEditingController _allergensController;
  late TextEditingController _energyController;
  late TextEditingController _fatController;
  late TextEditingController _sugarController;
  late TextEditingController _saltController;
  late TextEditingController _proteinController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _product = args['product'] as Product;
    _productId = args['productId'] as String;

    // Initialiser les contrôleurs avec les valeurs du produit
    _nameController = TextEditingController(text: _product.productName);
    _brandController = TextEditingController(text: _product.brands);
    _ingredientsController = TextEditingController(
      text: _product.ingredientsText,
    );
    _allergensController = TextEditingController(text: _product.allergens);
    _energyController = TextEditingController(
      text: _product.energy?.toString() ?? '',
    );
    _fatController = TextEditingController(
      text: _product.fat?.toString() ?? '',
    );
    _sugarController = TextEditingController(
      text: _product.sugar?.toString() ?? '',
    );
    _saltController = TextEditingController(
      text: _product.salt?.toString() ?? '',
    );
    _proteinController = TextEditingController(
      text: _product.protein?.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: _product.imageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _ingredientsController.dispose();
    _allergensController.dispose();
    _energyController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    _saltController.dispose();
    _proteinController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final updatedProduct = Product(
        productName: _nameController.text.trim(),
        brands: _brandController.text.trim(),
        ingredientsText: _ingredientsController.text.trim(),
        allergens: _allergensController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        energy: double.tryParse(_energyController.text) ?? 0.0,
        fat: double.tryParse(_fatController.text) ?? 0.0,
        sugar: double.tryParse(_sugarController.text) ?? 0.0,
        salt: double.tryParse(_saltController.text) ?? 0.0,
        protein: double.tryParse(_proteinController.text) ?? 0.0,
        nutriScore: _product.nutriScore,
        novaGroup: _product.novaGroup,
        ecoScore: _product.ecoScore,
      );

      final error = await _productService.updateProduct(
        updatedProduct,
        _productId,
      );
      setState(() => _isLoading = false);

      if (error == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Product updated successfully')));
        setState(() {
          _product = updatedProduct;
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete this product?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final error = await _productService.deleteProduct(_productId);
      setState(() => _isLoading = false);

      if (error == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Product deleted successfully')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Details'),
        actions: [
          if (!_isEditing)
            IconButton(icon: Icon(Icons.edit), onPressed: _toggleEditMode),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteProduct,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_product.imageUrl != null &&
                          _product.imageUrl!.isNotEmpty)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _product.imageUrl!,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.broken_image,
                                    size: 150,
                                    color: Color(0xFF757575),
                                  ),
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Enter product name' : null,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          labelText: 'Brand',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _ingredientsController,
                        decoration: InputDecoration(
                          labelText: 'Ingredients',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        maxLines: 3,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _allergensController,
                        decoration: InputDecoration(
                          labelText: 'Allergens',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _energyController,
                        decoration: InputDecoration(
                          labelText: 'Energy (kcal/100g)',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _fatController,
                        decoration: InputDecoration(
                          labelText: 'Fat (g/100g)',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _sugarController,
                        decoration: InputDecoration(
                          labelText: 'Sugar (g/100g)',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _saltController,
                        decoration: InputDecoration(
                          labelText: 'Salt (g/100g)',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _proteinController,
                        decoration: InputDecoration(
                          labelText: 'Protein (g/100g)',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 16),
                      if (_isEditing)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _saveChanges,
                              child: Text('Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4CAF50),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _toggleEditMode,
                              child: Text('Cancel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 16),
                      Text(
                        'Quality Score: ${_product.getQualityPercentage().toStringAsFixed(1)}/100',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Analysis: ${_product.analyze()}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Color(0xFF212121),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
