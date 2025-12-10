import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zaggar/screens/contact_screen.dart';
import 'package:zaggar/screens/my_data_screen.dart';
import 'package:zaggar/screens/food_preferences_screen.dart'; // Ajout de l'importation
import 'package:zaggar/screens/change_email_screen.dart';

const Color primaryColor = Color(0xFF00C853);
const Color errorColor = Color(0xFFD32F2F);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF212121);
const Color secondaryTextColor = Color(0xFF757575);
const Color darkBackgroundColor = Color(0xFF121212);
const Color darkCardColor = Color(0xFF1E1E1E);
const Color darkTextColor = Colors.white;
const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
const double cardElevation = 4.0;
const double cardBorderRadius = 12.0;
const double buttonBorderRadius = 8.0;
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

class SettingsScreen extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  SettingsScreen({required this.isDarkMode, required this.toggleTheme});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la déconnexion : $e',
            style: bodyStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Préférences',
              style: headlineStyle.copyWith(
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
              child: Column(
                children: [
                  Divider(height: 18, color: Theme.of(context).dividerColor),
                  ListTile(
                    title: Text(
                      'Mode sombre',
                      style: bodyStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: toggleTheme,
                      activeColor: primaryColor,
                    ),
                  ),
                  Divider(height: 18, color: Theme.of(context).dividerColor),
                  ListTile(
                    title: Text(
                      'Changer le mot de passe',
                      style: bodyStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 18, color: Theme.of(context).dividerColor),
                  ListTile(
                    title: Text(
                      'Changer l\'email',
                      style: bodyStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeEmailScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 18, color: Theme.of(context).dividerColor),
                  ListTile(
                    title: Text(
                      'Informations Personnelles',
                      style: bodyStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MyDataScreen(
                                isDarkMode: isDarkMode,
                                toggleTheme: toggleTheme,
                              ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 18, color: Theme.of(context).dividerColor),
                  ListTile(
                    title: Text(
                      'Préférences Alimentaires',
                      style: bodyStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FoodPreferencesScreen(
                                isDarkMode: isDarkMode,
                                toggleTheme: toggleTheme,
                              ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 18, color: Theme.of(context).dividerColor),
                  ListTile(
                    title: Text(
                      'Contactez-nous',
                      style: bodyStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 18, color: Theme.of(context).dividerColor),
                  ListTile(
                    title: Text(
                      'Déconnexion',
                      style: bodyStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    trailing: Icon(
                      Icons.logout,
                      size: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    onTap: () => _signOut(context),
                  ),
                  Divider(height: 18, color: Theme.of(context).dividerColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackbar('Aucun utilisateur connecté');
        setState(() => _isLoading = false);
        return;
      }

      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _oldPasswordController.text.trim(),
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text.trim());

        _showSuccessSnackbar('Mot de passe changé avec succès');
        _formKey.currentState!.reset();
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Navigator.pop(context);
      } catch (e) {
        String errorMessage = 'Erreur lors du changement de mot de passe';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'wrong-password':
              errorMessage = 'L\'ancien mot de passe est incorrect';
              break;
            case 'weak-password':
              errorMessage = 'Le nouveau mot de passe est trop faible';
              break;
            default:
              errorMessage = e.message ?? errorMessage;
          }
        }
        _showErrorSnackbar(errorMessage);
      } finally {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Changer le mot de passe',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier le mot de passe',
                style: headlineStyle.copyWith(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _oldPasswordController,
                          label: 'Ancien mot de passe',
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez l\'ancien mot de passe';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _newPasswordController,
                          label: 'Nouveau mot de passe',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez le nouveau mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: itemSpacing),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmer le mot de passe',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirmez le nouveau mot de passe';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: itemSpacing * 2),
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.save, size: 20),
                                label: Text(
                                  'Changer le mot de passe',
                                  style: buttonStyle,
                                ),
                                onPressed: _changePassword,
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
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: captionStyle.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      style: bodyStyle.copyWith(
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }
}

class ChangeEmailScreen extends StatefulWidget {
  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestEmailChange() async {
    if (_formKey.currentState!.validate()) {
      final newEmail = _emailController.text.trim();
      await _showPasswordDialog(newEmail);
    }
  }

  Future<void> _showPasswordDialog(String newEmail) async {
    final passwordController = TextEditingController();
    bool dialogLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardBorderRadius),
              ),
              title: Text(
                'Vérification requise',
                style: headlineStyle.copyWith(
                  fontSize: 20,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Entrez votre mot de passe actuel pour continuer.',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  SizedBox(height: itemSpacing),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: captionStyle.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor,
                    ),
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez votre mot de passe';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Annuler',
                    style: bodyStyle.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      dialogLoading
                          ? null
                          : () async {
                            setDialogState(() => dialogLoading = true);
                            await _verifyAndChangeEmail(
                              newEmail,
                              passwordController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonBorderRadius),
                    ),
                  ),
                  child:
                      dialogLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Vérifier', style: buttonStyle),
                ),
              ],
            );
          },
        );
      },
    );
    passwordController.dispose();
  }

  Future<void> _verifyAndChangeEmail(String newEmail, String password) async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar('Aucun utilisateur connecté');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail);

      _showSuccessSnackbar(
        'Un email de vérification a été envoyé à $newEmail. Cliquez sur le lien pour confirmer le changement.',
      );
      _formKey.currentState!.reset();
      _emailController.clear();
      Navigator.pop(context);
    } catch (e) {
      String errorMessage = 'Erreur lors du changement d\'email';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Le mot de passe est incorrect';
            break;
          case 'invalid-email':
            errorMessage = 'L\'email saisi est invalide';
            break;
          case 'email-already-in-use':
            errorMessage = 'Cet email est déjà utilisé';
            break;
          default:
            errorMessage = e.message ?? errorMessage;
        }
      }
      _showErrorSnackbar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Changer l\'email',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier l\'email',
                style: headlineStyle.copyWith(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Nouvel email',
                            labelStyle: captionStyle.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(
                              Icons.email,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(
                                  context,
                                ).inputDecorationTheme.fillColor,
                          ),
                          style: bodyStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Entrez un nouvel email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Entrez un email valide';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: itemSpacing * 2),
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.email, size: 20),
                                label: Text(
                                  'Changer l\'email',
                                  style: buttonStyle,
                                ),
                                onPressed: _requestEmailChange,
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
            ],
          ),
        ),
      ),
    );
  }
}
