import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zaggar/screens/contact_screen.dart';
import 'package:zaggar/screens/user_management_screen.dart';
import 'package:zaggar/screens/add_product_screen.dart';
import 'package:zaggar/screens/user_contact_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../services/product_service.dart';
import '../screens/role_manager.dart';

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

class BarcodeScannerScreen extends StatefulWidget {
  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final ProductService _productService = ProductService();
  late MobileScannerController _scannerController;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isLoading = false;
  int _currentIndex = 0;
  Product? _scannedProduct;
  bool _isFlashOn = false;
  String? _userRole;
  bool _isUploading = false;
  String? _userImageUrl;
  String? _coverImageUrl;
  final TextEditingController _historySearchController =
      TextEditingController();
  String _historySearchQuery = '';
  final TextEditingController _productsSearchController =
      TextEditingController();
  String _productsSearchQuery = '';
  Map<String, dynamic>? _predictionResult;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    WidgetsBinding.instance.addObserver(this);
    _loadUserRole();
    _loadUserProfileImage();
    if (_currentIndex == 0) {
      _startCamera();
    }
    _historySearchController.addListener(_onHistorySearchChanged);
    _productsSearchController.addListener(_onProductsSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _historySearchController.dispose();
    _productsSearchController.dispose();
    super.dispose();
  }

  void _initializeScanner() {
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _onHistorySearchChanged() {
    setState(() {
      _historySearchQuery = _historySearchController.text.toLowerCase();
    });
  }

  void _onProductsSearchChanged() {
    setState(() {
      _productsSearchQuery = _productsSearchController.text.toLowerCase();
    });
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await RoleManager.getUserRole(user);
      setState(() => _userRole = role);
    }
  }

  Future<void> _loadUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        setState(() {
          _userImageUrl = doc.data()?['imageUrl'];
          _coverImageUrl = doc.data()?['coverImageUrl'];
        });
      }
    }
  }

  Future<void> _startCamera() async {
    try {
      await _scannerController.start();
    } catch (e) {}
  }

  Future<void> _stopCamera() async {
    try {
      await _scannerController.stop();
    } catch (e) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _currentIndex == 0) {
      _startCamera();
    } else if (state == AppLifecycleState.paused) {
      _stopCamera();
    }
  }

  Future<void> _fetchProductInfo(String barcode) async {
    setState(() => _isLoading = true);
    try {
      final product = await _productService.fetchProduct(barcode);
      if (product != null) {
        setState(() {
          _scannedProduct = product;
          _predictionResult =
              null; // Réinitialiser explicitement pour éviter tout conflit
        });
        await _saveScanToFirestore(product, barcode);
        // Effectuer la prédiction uniquement pour ROLE_USER
        if (_userRole == RoleManager.ROLE_USER) {
          await _predictProductCompatibility(barcode);
        }
      } else {
        _showErrorSnackbar('Produit non trouvé pour le code-barres : $barcode');
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la récupération du produit : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _predictProductCompatibility(String barcode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.97:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user.uid, 'product_code': barcode}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() => _predictionResult = result);

        final recommendations = List<String>.from(result['recommendations']);
        final isCompatible =
            !result['allergen_conflict'] &&
            result['is_healthy'] &&
            result['vegetarian_compatible'];

        if (isCompatible) {
          _showSuccessSnackbar('Produit compatible avec vos préférences !');
        } else {
          _showErrorSnackbar(recommendations.join('\n'));
        }
      } else {
        _showErrorSnackbar(
          'Erreur lors de la prédiction : ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la prédiction : $e');
    }
  }

  Future<void> _saveScanToFirestore(Product product, String barcode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final scanQuery =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scans')
              .where('barcode', isEqualTo: barcode)
              .get();

      for (var doc in scanQuery.docs) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scans')
            .doc(doc.id)
            .delete();
      }

      final scanData = {
        'barcode': barcode,
        'productName': product.productName ?? 'Produit inconnu',
        'brands': product.brands ?? 'N/A',
        'ingredientsText': product.ingredientsText ?? 'N/A',
        'allergens': product.allergens ?? 'N/A',
        'imageUrl': product.imageUrl ?? '',
        'nutriScore': product.nutriScore ?? 'N/A',
        'novaGroup': product.novaGroup ?? 'N/A',
        'ecoScore': product.ecoScore ?? 'N/A',
        'energy': product.getEnergy(),
        'fat': product.getFat(),
        'sugar': product.getSugar(),
        'salt': product.getSalt(),
        'protein': product.getProtein(),
        'fiber': product.getFiber() ?? 0,
        'additives': product.getAdditives() ?? [],
        'qualityPercentage': product.getQualityPercentage(),
        'energyWUIndex': product.getEnergyIndex(),
        'nutritionalIndex': product.getNutritionalIndex(),
        'complianceIndex': product.getComplianceIndex(),
        'positiveAspects': product.getPositiveAspects(),
        'negativeAspects': product.getNegativeAspects(),
        'overallAnalysis': product.analyze(),
        'prediction': _predictionResult, // Will be null for ROLE_ENTERPRISE
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .add(scanData);
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'enregistrement du scan : $e');
    }
  }

  void _showErrorSnackbar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: bodyStyle.copyWith(color: Colors.white)),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: bodyStyle.copyWith(color: Colors.white)),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score <= 0) return errorColor;
    if (score >= 100) return primaryColor;
    final red = (255 * (100 - score) / 100).toInt();
    final green = (255 * score / 100).toInt();
    return Color.fromRGBO(red, green, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        appBar: _buildAppBar(),
        drawer: _buildDrawer(),
        body: SafeArea(bottom: true, child: _buildCurrentScreen()),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      title: Text(
        _getAppBarTitle(),
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      centerTitle: true,
      leading: Builder(
        builder:
            (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  backgroundImage:
                      _userImageUrl != null && _userImageUrl!.isNotEmpty
                          ? NetworkImage(_userImageUrl!)
                          : null,
                  child:
                      _userImageUrl == null || _userImageUrl!.isEmpty
                          ? Icon(
                            Icons.person,
                            size: 20,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          )
                          : null,
                ),
              ),
            ),
      ),
      actions: [
        if (_currentIndex == 0)
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            color: Theme.of(context).appBarTheme.iconTheme?.color,
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
                _scannerController.toggleTorch();
              });
            },
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'settings') {
              Navigator.pushNamed(context, '/settings');
            }
          },
          itemBuilder:
              (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Text(
                    'Paramètres',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
        ),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Scanner';
      case 1:
        return 'Historique';
      case 2:
        return 'Profil';
      case 3:
        if (_userRole == RoleManager.ROLE_ADMIN) return 'Utilisateurs';
        if (_userRole == RoleManager.ROLE_ENTERPRISE) return 'Ajouter Produit';
        if (_userRole == RoleManager.ROLE_USER) return 'Alertes';
        return 'Scanner';
      case 4:
        if (_userRole == RoleManager.ROLE_ADMIN)
          return 'Messages des utilisateurs';
        if (_userRole == RoleManager.ROLE_ENTERPRISE) return 'Mes Produits';
        return 'Scanner';
      case 5:
        return 'Contacter l\'admin';
      default:
        return 'Scanner';
    }
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: Container(
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                image:
                    _coverImageUrl != null && _coverImageUrl!.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(_coverImageUrl!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.5),
                            BlendMode.darken,
                          ),
                        )
                        : null,
                gradient:
                    _coverImageUrl == null || _coverImageUrl!.isEmpty
                        ? LinearGradient(
                          colors: [primaryColor, primaryDarkColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
              ),
              child: UserAccountsDrawerHeader(
                accountName: Text(
                  user?.displayName ?? 'Utilisateur',
                  style: subtitleStyle.copyWith(color: Colors.white),
                ),
                accountEmail: Text(
                  user?.email ?? 'N/A',
                  style: bodyStyle.copyWith(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  backgroundImage:
                      _userImageUrl != null && _userImageUrl!.isNotEmpty
                          ? NetworkImage(_userImageUrl!)
                          : null,
                  child:
                      _userImageUrl == null || _userImageUrl!.isEmpty
                          ? Icon(
                            Icons.person,
                            size: 40,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          )
                          : null,
                ),
                decoration: BoxDecoration(color: Colors.transparent),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.qr_code_scanner,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      'Scanner',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    selected: _currentIndex == 0,
                    onTap: () {
                      setState(() {
                        _currentIndex = 0;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.history,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      'Historique',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    selected: _currentIndex == 1,
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      'Profil',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    selected: _currentIndex == 2,
                    onTap: () {
                      setState(() {
                        _currentIndex = 2;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  if (_userRole == RoleManager.ROLE_USER)
                    ListTile(
                      leading: Icon(
                        Icons.warning,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Alertes',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      selected: _currentIndex == 3,
                      onTap: () {
                        setState(() {
                          _currentIndex = 3;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ListTile(
                    leading: Icon(
                      Icons.message,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      'Contacter l\'admin',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    selected: _currentIndex == 5,
                    onTap: () {
                      setState(() {
                        _currentIndex = 5;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  if (_userRole == RoleManager.ROLE_ADMIN) ...[
                    ListTile(
                      leading: Icon(
                        Icons.group,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Utilisateurs',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      selected: _currentIndex == 3,
                      onTap: () {
                        setState(() {
                          _currentIndex = 3;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.message,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Messages des utilisateurs',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      selected: _currentIndex == 4,
                      onTap: () {
                        setState(() {
                          _currentIndex = 4;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                  if (_userRole == RoleManager.ROLE_ENTERPRISE) ...[
                    ListTile(
                      leading: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Ajouter Produit',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      selected: _currentIndex == 3,
                      onTap: () {
                        setState(() {
                          _currentIndex = 3;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.list_alt,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      title: Text(
                        'Mes Produits',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      selected: _currentIndex == 4,
                      onTap: () {
                        setState(() {
                          _currentIndex = 4;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(defaultPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout, size: 20, color: Colors.white),
                  label: Text('Déconnexion', style: buttonStyle),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_userRole == null) {
      return Center(child: CircularProgressIndicator());
    }
    switch (_currentIndex) {
      case 0:
        return _buildScannerView();
      case 1:
        return _buildHistoryView();
      case 2:
        return _buildProfileView();
      case 3:
        if (_userRole == RoleManager.ROLE_ADMIN) return UserManagementScreen();
        if (_userRole == RoleManager.ROLE_ENTERPRISE) return AddProductScreen();
        if (_userRole == RoleManager.ROLE_USER) return _buildAlertsView();
        return _buildScannerView();
      case 4:
        if (_userRole == RoleManager.ROLE_ADMIN) return UserContactScreen();
        if (_userRole == RoleManager.ROLE_ENTERPRISE)
          return _buildMyProductsView();
        return _buildScannerView();
      case 5:
        return ContactScreen();
      default:
        return _buildScannerView();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              if (index == 0) {
                _scannedProduct = null;
                _isFlashOn = false;
                _scannerController = MobileScannerController(
                  facing: CameraFacing.back,
                  torchEnabled: false,
                );
                _startCamera();
              } else {
                _stopCamera();
              }
            });
          },
          items: _buildBottomNavItems(),
          backgroundColor: Theme.of(context).cardColor,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: captionStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: captionStyle,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    final baseItems = [
      BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profil',
      ),
    ];

    if (_userRole == RoleManager.ROLE_ADMIN) {
      return [
        ...baseItems,
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Utilisateurs'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
      ];
    } else if (_userRole == RoleManager.ROLE_ENTERPRISE) {
      return [
        ...baseItems,
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Ajouter',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: 'Mes Produits',
        ),
      ];
    } else if (_userRole == RoleManager.ROLE_USER) {
      return [
        ...baseItems,
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: 'Alertes'),
      ];
    }
    return baseItems;
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            if (!_isLoading) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue ?? '';
                if (barcode.isNotEmpty) {
                  _fetchProductInfo(barcode);
                }
              }
            }
          },
          errorBuilder: (context, error, child) {
            return Center(
              child: Text(
                'Erreur avec le scanner : $error',
                style: bodyStyle.copyWith(color: errorColor),
              ),
            );
          },
        ),
        Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: 270,
              height: 135,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1122),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2.0,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child:
              _isLoading
                  ? Container(
                    margin: EdgeInsets.only(bottom: 80),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : _scannedProduct == null
                  ? Container(
                    margin: EdgeInsets.only(bottom: 80),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Scannez un code-barres pour analyser un produit',
                      style: bodyStyle.copyWith(color: Colors.white),
                    ),
                  )
                  : _buildProductCard(),
        ),
      ],
    );
  }

  Widget _buildProductCard() {
    if (_scannedProduct == null) return SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        final product = _scannedProduct;
        if (product != null) {
          Navigator.pushNamed(context, '/product', arguments: product);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 80, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _scannedProduct?.imageUrl != null &&
                                _scannedProduct!.imageUrl!.isNotEmpty
                            ? Image.network(
                              _scannedProduct!.imageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                  ),
                            )
                            : Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _scannedProduct?.productName ?? 'Produit inconnu',
                          style: subtitleStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Marque : ${_scannedProduct?.brands ?? 'N/A'}',
                          style: captionStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        if (_predictionResult != null &&
                            _userRole == RoleManager.ROLE_USER) ...[
                          SizedBox(height: 4),
                          Text(
                            'Compatibilité: ${_predictionResult!['is_healthy'] ? 'Sain' : 'Non sain'} | Allergènes: ${_predictionResult!['allergen_conflict'] ? 'Conflit' : 'Aucun'} | Végétarien: ${_predictionResult!['vegetarian_compatible'] ? 'Oui' : 'Non'}',
                            style: captionStyle.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onPressed: () {
                      setState(() {
                        _scannedProduct = null;
                        _predictionResult = null;
                        _startCamera();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildQualityScore(
                _scannedProduct?.getQualityPercentage() ?? 0.0,
              ),
              if (_predictionResult != null &&
                  _userRole == RoleManager.ROLE_USER &&
                  _predictionResult!['recommendations'].isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List<Widget>.generate(
                      _predictionResult!['recommendations'].length,
                      (index) => Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          '- ${_predictionResult!['recommendations'][index]}',
                          style: bodyStyle.copyWith(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityScore(double score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Score qualité :',
          style: bodyStyle.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getScoreColor(score).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getScoreColor(score)),
          ),
          child: Row(
            children: [
              Text(
                '${score.toStringAsFixed(1)}/100',
                style: bodyStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(score),
                ),
              ),
              SizedBox(width: 4),
              Icon(
                score >= 50 ? Icons.thumb_up : Icons.thumb_down,
                size: 16,
                color: _getScoreColor(score),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsView() {
    _stopCamera();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: TextField(
            controller: _historySearchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans les alertes...',
              hintStyle: captionStyle.copyWith(
                color: Theme.of(context).hintColor,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            style: bodyStyle.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('scans')
                    .orderBy('timestamp', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur de chargement des alertes',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 48,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune alerte disponible',
                        style: subtitleStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final filteredDocs =
                  snapshot.data!.docs.where((doc) {
                    final scanData = doc.data() as Map<String, dynamic>;
                    final productName =
                        (scanData['productName'] ?? '')
                            .toString()
                            .toLowerCase();
                    final brands =
                        (scanData['brands'] ?? '').toString().toLowerCase();
                    return productName.contains(_historySearchQuery) ||
                        brands.contains(_historySearchQuery);
                  }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun résultat trouvé',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(defaultPadding),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final scanData =
                      filteredDocs[index].data() as Map<String, dynamic>;
                  final docId = filteredDocs[index].id;
                  return _buildAlertCard(scanData, docId);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> scanData, String docId) {
    final prediction = scanData['prediction'] as Map<String, dynamic>? ?? {};
    final recommendations = List<String>.from(
      prediction['recommendations'] ?? [],
    );
    final timestamp =
        scanData['timestamp'] != null
            ? (scanData['timestamp'] as Timestamp)
                .toDate()
                .toString()
                .substring(0, 16)
            : 'N/A';
    final isCompatible =
        !(prediction['allergen_conflict'] ?? false) &&
        (prediction['is_healthy'] ?? false) &&
        (prediction['vegetarian_compatible'] ?? false);

    return Card(
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      scanData['imageUrl'] != null &&
                              scanData['imageUrl'].isNotEmpty
                          ? Image.network(
                            scanData['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                ),
                          )
                          : Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                ),
                SizedBox(width: itemSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scanData['productName'] ?? 'Produit inconnu',
                        style: subtitleStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Marque : ${scanData['brands'] ?? 'N/A'}',
                        style: captionStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Scanné : $timestamp',
                        style: captionStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: itemSpacing),
            Text(
              'Compatibilité: ${prediction['is_healthy'] ?? false ? 'Sain' : 'Non sain'} | '
              'Allergènes: ${prediction['allergen_conflict'] ?? false ? 'Conflit' : 'Aucun'} | '
              'Végétarien: ${prediction['vegetarian_compatible'] ?? false ? 'Oui' : 'Non'}',
              style: bodyStyle.copyWith(
                color: isCompatible ? primaryColor : errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (recommendations.isNotEmpty) ...[
              SizedBox(height: 8),
              ...recommendations.map(
                (rec) => Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    '- $rec',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: itemSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .collection('scans')
                        .doc(docId)
                        .delete();
                    _showSuccessSnackbar('Alerte supprimée');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    _stopCamera();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: TextField(
            controller: _historySearchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans l\'historique...',
              hintStyle: captionStyle.copyWith(
                color: Theme.of(context).hintColor,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            style: bodyStyle.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('scans')
                    .orderBy('timestamp', descending: true)
                    .limit(50)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur de chargement de l\'historique',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun historique de scan disponible',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                );
              }

              final filteredDocs =
                  snapshot.data!.docs.where((doc) {
                    final scanData = doc.data() as Map<String, dynamic>;
                    final productName =
                        (scanData['productName'] ?? '')
                            .toString()
                            .toLowerCase();
                    final brands =
                        (scanData['brands'] ?? '').toString().toLowerCase();
                    return productName.contains(_historySearchQuery) ||
                        brands.contains(_historySearchQuery);
                  }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun résultat trouvé',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final scanData =
                      filteredDocs[index].data() as Map<String, dynamic>;
                  final qualityPercentage =
                      scanData['qualityPercentage'] as double? ?? 0.0;
                  final docId = filteredDocs[index].id;

                  return _buildHistoryCard(scanData, qualityPercentage, docId);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> scanData,
    double qualityPercentage,
    String docId,
  ) {
    return GestureDetector(
      onTap: () {
        final product = Product.fromFirestore(scanData);
        Navigator.pushNamed(context, '/product', arguments: product);
      },
      child: Card(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Stack(
            children: [
              SizedBox(
                height: 300,
                child: ListView(
                  physics: ClampingScrollPhysics(),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          scanData['imageUrl'] != null &&
                                  scanData['imageUrl'].isNotEmpty
                              ? Image.network(
                                scanData['imageUrl'],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: 120,
                                      color:
                                          Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor,
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 60,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                      ),
                                    ),
                              )
                              : Container(
                                height: 120,
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                ),
                              ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      scanData['productName'] ?? 'Produit inconnu',
                      style: subtitleStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Marque : ${scanData['brands'] ?? 'N/A'}',
                      style: captionStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Scanné : ${scanData['timestamp'] != null ? (scanData['timestamp'] as Timestamp).toDate().toString().substring(0, 16) : 'N/A'}',
                      style: captionStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('scans')
                            .doc(docId)
                            .delete();
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Scan supprimé',
                              style: bodyStyle.copyWith(color: Colors.white),
                            ),
                            backgroundColor: primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    _stopCamera();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil',
            style: headlineStyle.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(height: itemSpacing),
          StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Text(
                  'Données de profil non trouvées',
                  style: bodyStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                );
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              return _buildProfileCard(user, userData);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(User user, Map<String, dynamic> userData) {
    final username = userData['username'] ?? 'Non défini';
    final description = userData['description'] ?? 'Aucune description';
    final imageUrl = userData['imageUrl'] ?? '';
    final coverImageUrl = userData['coverImageUrl'] ?? '';
    final age = userData['age']?.toString() ?? 'Non défini';
    final allergies =
        userData['allergies'] is List
            ? (userData['allergies'] as List).join(', ')
            : 'Aucune';
    final isVegetarian = userData['is_vegetarian'] == true ? 'Oui' : 'Non';
    final calorieLimit = userData['calorie_limit']?.toString() ?? 'Non défini';

    return Card(
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
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Cover Image
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(cardBorderRadius),
                        topRight: Radius.circular(cardBorderRadius),
                      ),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child:
                            coverImageUrl.isNotEmpty
                                ? Image.network(
                                  coverImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.broken_image,
                                        size: 60,
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                      ),
                                )
                                : Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                ),
                      ),
                    ),
                    if (!_isUploading)
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: primaryColor,
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed:
                              () => _updateProfileImage(context, isCover: true),
                        ),
                      ),
                    if (_isUploading)
                      Positioned(
                        bottom: 8,
                        right: 8,
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
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Profile Image (positioned to overlap half over cover image)
                Positioned(
                  top:
                      60, // Half of the profile image height (120/2) to overlap
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child:
                            imageUrl.isEmpty
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
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: primaryColor,
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                            onPressed:
                                () => _updateProfileImage(
                                  context,
                                  isCover: false,
                                ),
                          ),
                        ),
                      if (_isUploading)
                        Positioned(
                          bottom: 8,
                          right: 8,
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
                ),
              ],
            ),
            SizedBox(
              height: itemSpacing + 60,
            ), // Space for the lower half of profile image
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileInfoItem('Nom d\'utilisateur', username),
                _buildProfileInfoItem('Email', user.email ?? 'Non disponible'),
                _buildProfileInfoItem('Description', description),
                _buildProfileInfoItem('Âge', age),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileInfoItem('Allergies', allergies),
                _buildProfileInfoItem('Végétarien', isVegetarian),
                _buildProfileInfoItem(
                  'Limite de calories',
                  '$calorieLimit kcal/jour',
                ),
              ],
            ),
            SizedBox(height: itemSpacing * 2),
            SizedBox(height: itemSpacing),
            _buildActionButton('Déconnexion', Icons.logout, () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            }, color: errorColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: captionStyle.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: bodyStyle.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed, {
    bool isLoading = false,
    Color color = primaryColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                : Icon(icon, size: 20, color: Colors.white),
        label: Text(text, style: buttonStyle),
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _updateProfileImage(
    BuildContext context, {
    required bool isCover,
  }) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final imageFile = File(image.path);
      final imageUrl = await _uploadImageToImgBB(imageFile);

      if (imageUrl == null) {
        _showErrorSnackbar('Échec du téléversement de l\'image');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({isCover ? 'coverImageUrl' : 'imageUrl': imageUrl});

      setState(() {
        if (isCover) {
          _coverImageUrl = imageUrl;
        } else {
          _userImageUrl = imageUrl;
        }
      });

      _showSuccessSnackbar(
        isCover
            ? 'Photo de couverture mise à jour'
            : 'Photo de profil mise à jour',
      );
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

  Widget _buildMyProductsView() {
    _stopCamera();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: TextField(
            controller: _productsSearchController,
            decoration: InputDecoration(
              hintText: 'Rechercher dans mes produits...',
              hintStyle: captionStyle.copyWith(
                color: Theme.of(context).hintColor,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            style: bodyStyle.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('products')
                    .where('addedBy', isEqualTo: user.uid)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur de chargement des produits',
                    style: bodyStyle.copyWith(color: errorColor),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 48,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucun produit ajouté pour le moment',
                        style: subtitleStyle.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final filteredDocs =
                  snapshot.data!.docs.where((doc) {
                    final productData = doc.data() as Map<String, dynamic>;
                    final productName =
                        (productData['productName'] ?? '')
                            .toString()
                            .toLowerCase();
                    final brands =
                        (productData['brands'] ?? '').toString().toLowerCase();
                    return productName.contains(_productsSearchQuery) ||
                        brands.contains(_productsSearchQuery);
                  }).toList();

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun résultat trouvé',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(defaultPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: defaultPadding,
                  mainAxisSpacing: defaultPadding,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final productData =
                      filteredDocs[index].data() as Map<String, dynamic>;
                  final product = Product.fromFirestore(productData);
                  final productId = filteredDocs[index].id;

                  return _buildMyProductCard(product, productId);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyProductCard(Product product, String productId) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product_added',
          arguments: {'product': product, 'productId': productId},
        );
      },
      child: Card(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: ClampingScrollPhysics(),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                    product.imageUrl!,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 100,
                                              width: 100,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color:
                                                    Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.color,
                                              ),
                                            ),
                                  )
                                  : Container(
                                    height: 100,
                                    width: 100,
                                    color:
                                        Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.productName ?? 'Produit inconnu',
                            style: subtitleStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Marque : ${product.brands ?? 'N/A'}',
                      style: captionStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Score : ${product.getQualityPercentage().toStringAsFixed(1)}/100',
                      style: captionStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/product_added',
                        arguments: {'product': product, 'productId': productId},
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[300], size: 20),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('products')
                          .doc(productId)
                          .delete();
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Produit supprimé',
                            style: bodyStyle.copyWith(color: Colors.white),
                          ),
                          backgroundColor: primaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
