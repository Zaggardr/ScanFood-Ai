import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

const String IMGBB_API_KEY = '94b9a844826404f4f9d3a347673ce463';
const Color primaryColor = Color(0xFF00C853);
const Color errorColor = Color(0xFFD32F2F);
const double cardElevation = 4.0;
const double cardBorderRadius = 12.0;
const double defaultPadding = 16.0;
const double itemSpacing = 12.0;

final TextStyle headlineStyle = GoogleFonts.poppins(
  fontSize: 24,
  fontWeight: FontWeight.bold,
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

class MyDataScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const MyDataScreen({required this.isDarkMode, required this.toggleTheme});

  @override
  _MyDataScreenState createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageController = TextEditingController();
  final _calorieLimitController = TextEditingController();
  bool _isLoading = false;
  bool _isUploading = false;
  String? _imageUrl;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    _calorieLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email;
      });
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['username'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _calorieLimitController.text =
              data['calorie_limit']?.toString() ?? '';
          _imageUrl = data['imageUrl'];
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar('Utilisateur non connecté');
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': _nameController.text,
        'email': _email,
        'description': _descriptionController.text,
        'age': int.tryParse(_ageController.text) ?? 30,
        'calorie_limit': int.tryParse(_calorieLimitController.text) ?? 500,
        'imageUrl': _imageUrl ?? '',
      }, SetOptions(merge: true));

      _showSuccessSnackbar('Profil mis à jour avec succès');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final imageFile = File(image.path);
      final imageUrl = await _uploadImageToImgBB(imageFile);

      if (imageUrl == null) {
        _showErrorSnackbar("Échec du téléversement de l'image");
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'imageUrl': imageUrl});

      setState(() => _imageUrl = imageUrl);
      _showSuccessSnackbar('Photo de profil mise à jour');
    } catch (e) {
      _showErrorSnackbar('Échec de la mise à jour : $e');
    } finally {
      setState(() => _isUploading = false);
    }
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
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: bodyStyle.copyWith(color: Colors.white)),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: bodyStyle.copyWith(color: Colors.white)),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Informations Personnelles',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations Personnelles',
                style: subtitleStyle.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).inputDecorationTheme.fillColor,
                            backgroundImage:
                                _imageUrl != null &&
                                        (_imageUrl?.isNotEmpty ?? false)
                                    ? NetworkImage(_imageUrl!)
                                    : null,
                            child:
                                _imageUrl == null ||
                                        (_imageUrl?.isEmpty ?? true)
                                    ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                    )
                                    : null,
                          ),
                          if (!_isUploading)
                            FloatingActionButton(
                              mini: true,
                              backgroundColor: primaryColor,
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                              onPressed: _updateProfileImage,
                            ),
                          if (_isUploading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: itemSpacing),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Nom d'utilisateur",
                          labelStyle: captionStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor,
                        ),
                        style: bodyStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: itemSpacing),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: captionStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor,
                        ),
                        style: bodyStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: itemSpacing),
                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'Âge',
                          labelStyle: captionStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor,
                        ),
                        style: bodyStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final age = int.tryParse(value);
                            if (age == null || age < 18 || age > 120) {
                              return 'Veuillez entrer un âge valide (18-120)';
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: itemSpacing),
                      TextFormField(
                        controller: _calorieLimitController,
                        decoration: InputDecoration(
                          labelText: 'Limite de calories (kcal/jour)',
                          labelStyle: captionStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).inputDecorationTheme.fillColor,
                        ),
                        style: bodyStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final limit = int.tryParse(value);
                            if (limit == null ||
                                limit < 100 ||
                                limit > 100000) {
                              return 'Veuillez entrer une limite valide (100-5000)';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: itemSpacing * 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : Text('Sauvegarder', style: buttonStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
