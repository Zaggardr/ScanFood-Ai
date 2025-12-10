import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart' as barcode_widget;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../services/product_service.dart';

// Constantes de design
const String IMGBB_API_KEY = '94b9a844826404f4f9d3a347673ce463';
const Color primaryColor = Color(0xFF00C853);
const Color primaryDarkColor = Color(0xFF009624);
const Color primaryLightColor = Color(0xFF5EFC82);
const Color secondaryColor = Color(0xFF69F0AE);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF212121);
const Color secondaryTextColor = Color(0xFF757575);
const Color errorColor = Color(0xFFD32F2F);
const Color darkBackgroundColor = Color(0xFF121212);
const Color darkCardColor = Color(0xFF1E1E1E);
const Color darkTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const double cardElevation = 4.0;
const double cardBorderRadius = 12.0;
const double buttonBorderRadius = 8.0;
const double defaultPadding = 16.0;
const double itemSpacing = 12.0;

// Styles de texte communs
final TextStyle headlineStyle = GoogleFonts.poppins(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

final TextStyle titleStyle = GoogleFonts.poppins(
  fontSize: 20,
  fontWeight: FontWeight.w600,
);

final TextStyle subtitleStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w500,
);

final TextStyle bodyStyle = GoogleFonts.poppins(fontSize: 14);

final TextStyle captionStyle = GoogleFonts.poppins(fontSize: 12);

final TextStyle buttonStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _allergensController = TextEditingController();
  final _energyController = TextEditingController();
  final _fatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _saltController = TextEditingController();
  final _proteinController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _nutriScoreController = TextEditingController();
  final _novaGroupController = TextEditingController();
  final _ecoScoreController = TextEditingController();
  final ProductService _productService = ProductService();
  bool _isLoading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  String? _generatedBarcode;

  @override
  void dispose() {
    _barcodeController.dispose();
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
    _nutriScoreController.dispose();
    _novaGroupController.dispose();
    _ecoScoreController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageToImgBB(File image) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$IMGBB_API_KEY');

    try {
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final jsonData = jsonDecode(responseData.body);
        return jsonData['data']['url'];
      } else {
        print('Erreur ImgBB: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Erreur lors du téléversement vers ImgBB: $e');
      return null;
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Aucune image sélectionnée',
            style: bodyStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageFile = File(image.path);
      final imageUrl = await _uploadImageToImgBB(imageFile);

      if (imageUrl != null) {
        _imageUrlController.text = imageUrl;
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Image téléversée avec succès',
              style: bodyStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Échec du téléversement de l\'image',
              style: bodyStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du téléversement : $e',
            style: bodyStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final product = Product(
        productName: _nameController.text.trim(),
        brands:
            _brandController.text.trim().isEmpty
                ? null
                : _brandController.text.trim(),
        ingredientsText:
            _ingredientsController.text.trim().isEmpty
                ? null
                : _ingredientsController.text.trim(),
        allergens:
            _allergensController.text.trim().isEmpty
                ? null
                : _allergensController.text.trim(),
        imageUrl:
            _imageUrlController.text.trim().isEmpty
                ? null
                : _imageUrlController.text.trim(),
        energy: double.tryParse(_energyController.text) ?? 0.0,
        fat: double.tryParse(_fatController.text) ?? 0.0,
        sugar: double.tryParse(_sugarController.text) ?? 0.0,
        salt: double.tryParse(_saltController.text) ?? 0.0,
        protein: double.tryParse(_proteinController.text) ?? 0.0,
        nutriScore:
            _nutriScoreController.text.trim().isEmpty
                ? null
                : _nutriScoreController.text.trim(),
        novaGroup:
            _novaGroupController.text.trim().isEmpty
                ? null
                : _novaGroupController.text.trim(),
        ecoScore:
            _ecoScoreController.text.trim().isEmpty
                ? null
                : _ecoScoreController.text.trim(),
      );

      final barcode = _barcodeController.text.trim();
      final error = await _productService.addProduct(product, barcode);

      if (error == null) {
        setState(() {
          _generatedBarcode = barcode;
        });

        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Produit ajouté avec succès',
              style: bodyStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        _formKey.currentState!.reset();
        _barcodeController.clear();
        _nameController.clear();
        _brandController.clear();
        _ingredientsController.clear();
        _allergensController.clear();
        _energyController.clear();
        _fatController.clear();
        _sugarController.clear();
        _saltController.clear();
        _proteinController.clear();
        _imageUrlController.clear();
        _nutriScoreController.clear();
        _novaGroupController.clear();
        _ecoScoreController.clear();
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              error,
              style: bodyStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        body: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau produit',
                style: headlineStyle.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: itemSpacing),
              Card(
                elevation: cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardBorderRadius),
                ),
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _barcodeController,
                          label: 'Code-barres',
                          icon: Icons.qr_code,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez un code-barres';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _nameController,
                          label: 'Nom du produit',
                          icon: Icons.label,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez le nom du produit';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _brandController,
                          label: 'Marque',
                          icon: Icons.branding_watermark,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _ingredientsController,
                          label: 'Ingrédients',
                          icon: Icons.food_bank,
                          maxLines: 3,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _allergensController,
                          label: 'Allergènes',
                          icon: Icons.warning,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _energyController,
                          label: 'Énergie (kcal/100g)',
                          icon: Icons.bolt,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _fatController,
                          label: 'Matières grasses (g/100g)',
                          icon: Icons.fastfood,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _sugarController,
                          label: 'Sucres (g/100g)',
                          icon: Icons.cake,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _saltController,
                          label: 'Sel (g/100g)',
                          icon: Icons.spa,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _proteinController,
                          label: 'Protéines (g/100g)',
                          icon: Icons.fitness_center,
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _nutriScoreController,
                          label: 'Nutri-Score (A-E)',
                          icon: Icons.score,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _novaGroupController,
                          label: 'NOVA Group (1-4)',
                          icon: Icons.star,
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _ecoScoreController,
                          label: 'Eco-Score (A-E)',
                          icon: Icons.eco,
                        ),
                        SizedBox(height: itemSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _imageUrlController,
                                label: 'URL de l\'image',
                                icon: Icons.image,
                                readOnly: true,
                              ),
                            ),
                            SizedBox(width: itemSpacing),
                            IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onPressed:
                                  _isLoading ? null : _pickAndUploadImage,
                            ),
                          ],
                        ),
                        SizedBox(height: itemSpacing * 2),
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.add, size: 20),
                                label: Text(
                                  'Ajouter le produit',
                                  style: buttonStyle,
                                ),
                                onPressed: _addProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      buttonBorderRadius,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_generatedBarcode != null) ...[
                SizedBox(height: itemSpacing * 2),
                Text(
                  'Code-barres généré',
                  style: subtitleStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                SizedBox(height: itemSpacing),
                Card(
                  elevation: cardElevation,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cardBorderRadius),
                  ),
                  color: Theme.of(context).cardColor,
                  child: Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Code-barres généré',
                              style: subtitleStyle.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: errorColor,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _generatedBarcode = null;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: itemSpacing),
                        barcode_widget.BarcodeWidget(
                          barcode: barcode_widget.Barcode.code128(),
                          data: _generatedBarcode!,
                          width: 200,
                          height: 80,
                          drawText: true,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: captionStyle.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon, color: Theme.of(context).iconTheme.color),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      style: bodyStyle.copyWith(
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
    );
  }
}
