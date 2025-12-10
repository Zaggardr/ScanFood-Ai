import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zaggar/screens/barcode_scanner_screen.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'dart:math';
import 'package:mailer/smtp_server.dart';
import '../services/user_service.dart';
import '../screens/role_manager.dart';

// Constantes de design (unchanged)
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

// Styles de texte communs (unchanged)
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

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = RoleManager.ROLE_USER;
  bool _isLoading = false;
  bool _isAdmin = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  String _generatePassword() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%';
    final Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        12,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<bool> _sendCredentialsEmail(String email, String password) async {
    final String smtpEmail = 'bokarrobak@gmail.com';
    final String smtpAppPassword = 'vqqn ehyo zpit ykbp';

    if (smtpEmail.isEmpty || smtpAppPassword.isEmpty) {
      print('Erreur: Identifiants SMTP non configurés');
      return false;
    }

    final smtpServer = gmail(smtpEmail, smtpAppPassword);
    final message = mailer.Message();
    message.from = mailer.Address(smtpEmail, 'Scan4Health');
    message.recipients = [mailer.Address(email)];
    message.subject = 'Vos identifiants pour l\'application';
    message.text = '''Bonjour,

Votre compte a été créé avec succès. Voici vos identifiants :
Email: $email
Mot de passe: $password

Veuillez vérifier votre email pour activer votre compte.
Cordialement,
L'équipe de l'application''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email envoyé: ${sendReport.toString()}');
      return true;
    } catch (e, stackTrace) {
      print('Erreur SMTP: $e\nStackTrace: $stackTrace');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Échec de l\'envoi de l\'email : $e',
            style: bodyStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return false;
    }
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          final role = doc.get('role') as String?;
          setState(() {
            _isAdmin = role == 'admin';
          });
        }
      } catch (e) {
        print('Erreur lors de la vérification du statut admin : $e');
      }
    }
  }

  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    return doc.exists && doc.get('role') == 'admin';
  }

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (await RoleManager.getUserRole(userCredential.user!) ==
          RoleManager.ROLE_ADMIN) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({'tempPassword': password}, SetOptions(merge: true));
      }

      return userCredential;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'tempPassword': FieldValue.delete()},
      );
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _createUser() async {
    if (!await isAdmin()) {
      throw Exception('Seul l\'admin peut créer des utilisateurs');
    }

    if (_formKey.currentState!.validate() && _isAdmin) {
      setState(() => _isLoading = true);

      try {
        final admin = FirebaseAuth.instance.currentUser;
        final adminEmail = admin?.email;
        final adminPassword = 'admina';

        final password = _generatePassword();
        final email = _emailController.text.trim();

        await _sendCredentialsEmail(email, password);

        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        _emailController.clear();

        if (userCredential.user != null) {
          await userCredential.user!.sendEmailVerification();
          await RoleManager.setUserRole(
            userCredential.user!,
            _selectedRole,
            username: 'nom',
            imageUrl: 'imageUrl',
          );
        }

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail!,
          password: adminPassword,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => BarcodeScannerScreen()),
        );

        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Utilisateur créé avec succès',
              style: bodyStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Erreur: ${e.toString()}',
              style: bodyStyle.copyWith(color: Colors.white),
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            children: [
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
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: captionStyle.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.email,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(
                                  context,
                                ).inputDecorationTheme.fillColor,
                          ),
                          style: bodyStyle.copyWith(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez un email';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Entrez un email valide';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: itemSpacing),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Rôle',
                            labelStyle: captionStyle.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.people,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(
                                  context,
                                ).inputDecorationTheme.fillColor,
                          ),
                          style: bodyStyle.copyWith(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: RoleManager.ROLE_USER,
                              child: Text('Utilisateur'),
                            ),
                            DropdownMenuItem(
                              value: RoleManager.ROLE_ENTERPRISE,
                              child: Text('Entreprise'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                        SizedBox(height: itemSpacing * 2),
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                              icon: Icon(Icons.person_add, size: 20),
                              label: Text(
                                'Créer Utilisateur',
                                style: buttonStyle,
                              ),
                              onPressed: _createUser,
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
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: itemSpacing),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
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
              SizedBox(height: itemSpacing),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur : ${snapshot.error}',
                          style: bodyStyle.copyWith(color: errorColor),
                        ),
                      );
                    }
                    final users =
                        snapshot.data!.docs.where((doc) {
                          final userData = doc.data() as Map<String, dynamic>;
                          final email =
                              (userData['email'] ?? '')
                                  .toString()
                                  .toLowerCase();
                          return email.contains(_searchQuery);
                        }).toList();

                    if (users.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun utilisateur trouvé',
                          style: bodyStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userData =
                            users[index].data() as Map<String, dynamic>;
                        final uid = users[index].id;
                        final imageUrl = userData['imageUrl'] ?? '';
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < users.length - 1 ? itemSpacing : 0,
                          ),
                          child: SizedBox(
                            width: 200, // Fixed width for each card
                            child: _buildUserCard(
                              context,
                              userData,
                              uid,
                              imageUrl,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> userData,
    String uid,
    String imageUrl,
  ) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // User photo
            CircleAvatar(
              radius: 50, // Larger size for the avatar
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child:
                  imageUrl.isEmpty
                      ? Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      )
                      : null,
            ),
            SizedBox(height: itemSpacing),
            // Username and role
            Column(
              children: [
                Text(
                  userData['email'] ?? 'Aucun email',
                  style: subtitleStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'Rôle : ${userData['role']}',
                  style: captionStyle.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            Spacer(),
            // Management buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    _showEditDialog(context, uid, userData);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20, color: errorColor),
                  onPressed: () async {
                    final error = await _userService.deleteUser(uid);
                    if (error == null) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Utilisateur supprimé',
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
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String uid,
    Map<String, dynamic> userData,
  ) {
    String selectedRole = userData['role'];

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              'Modifier l\'utilisateur',
              style: subtitleStyle.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Rôle',
                    labelStyle: captionStyle.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                  ),
                  style: bodyStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: RoleManager.ROLE_USER,
                      child: Text('Utilisateur'),
                    ),
                    DropdownMenuItem(
                      value: RoleManager.ROLE_ENTERPRISE,
                      child: Text('Entreprise'),
                    ),
                  ],
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Annuler',
                  style: bodyStyle.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final error = await _userService.updateUser(
                    uid: uid,
                    role: selectedRole,
                  );
                  Navigator.of(ctx).pop();
                  if (error == null) {
                    _scaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Utilisateur mis à jour',
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
                },
                child: Text(
                  'Enregistrer',
                  style: bodyStyle.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
