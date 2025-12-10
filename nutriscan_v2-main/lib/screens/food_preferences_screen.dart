import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

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

class FoodPreferencesScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const FoodPreferencesScreen({
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  _FoodPreferencesScreenState createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends State<FoodPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isVegetarian = false;
  bool _isLoading = false;
  List<String> _userAllergies = [];
  List<String> _availableAllergens = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAvailableAllergens();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isVegetarian = data['is_vegetarian'] ?? false;
          _userAllergies =
              data['allergies'] is List
                  ? List<String>.from(data['allergies'])
                  : [];
        });
      }
    }
  }

  Future<void> _loadAvailableAllergens() async {
    setState(() => _isLoading = true);
    try {
      print(
        'Tentative de connexion à l\'API : http://192.168.1.97:5000/allergens',
      );
      final response = await http.get(
        Uri.parse('http://192.168.1.97:5000/allergens'),
      );
      print('Réponse reçue avec le statut : ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Données reçues : $data');
        setState(() {
          _availableAllergens = List<String>.from(data['allergens']);
        });
      } else {
        print('Échec de la requête, statut : ${response.statusCode}');
        _showErrorSnackbar(
          'Échec de la récupération des allergènes depuis l\'API. Statut : ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur lors de la récupération des allergènes : $e');
      _showErrorSnackbar('Erreur lors de la récupération des allergènes : $e');
    } finally {
      setState(() => _isLoading = false);
      print(
        'Chargement des allergènes terminé. Allergènes disponibles : $_availableAllergens',
      );
    }
  }

  Future<void> _savePreferences() async {
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
        'is_vegetarian': _isVegetarian,
        'allergies': _userAllergies,
      }, SetOptions(merge: true));

      _showSuccessSnackbar('Préférences alimentaires mises à jour avec succès');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour : $e');
    } finally {
      setState(() => _isLoading = false);
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
          'Préférences Alimentaires',
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
                'Préférences Alimentaires',
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
                      CheckboxListTile(
                        title: Text(
                          'Végétarien',
                          style: bodyStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        value: _isVegetarian,
                        onChanged: (value) {
                          setState(() => _isVegetarian = value ?? false);
                        },
                        activeColor: primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                      Divider(),
                      Text(
                        'Allergies',
                        style: subtitleStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      SizedBox(height: itemSpacing),
                      if (_isLoading)
                        Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        )
                      else if (_availableAllergens.isEmpty)
                        Text(
                          'Aucun allergène disponible',
                          style: captionStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        )
                      else
                        ..._availableAllergens.map((allergen) {
                          return CheckboxListTile(
                            title: Text(
                              allergen.capitalize(),
                              style: bodyStyle.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                              ),
                            ),
                            value: _userAllergies.contains(allergen),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _userAllergies.add(allergen);
                                } else {
                                  _userAllergies.remove(allergen);
                                }
                              });
                            },
                            activeColor: primaryColor,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: itemSpacing * 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePreferences,
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
