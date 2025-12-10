import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/auth_utils.dart';
import 'role_manager.dart';

// Constantes de design
const Color primaryColor = Color(
  0xFF00C853,
); // Vert pour les actions principales
const Color secondaryColor = Color(
  0xFF757575,
); // Gris pour les textes secondaires
const Color backgroundColor = Color(0xFFF5F5F5); // Fond clair
const Color cardColor = Colors.white; // Couleur des cartes
const double defaultPadding = 24.0;
const double buttonBorderRadius = 12.0;
const double cardElevation = 6.0;
const double cardBorderRadius = 16.0;

// Styles de texte
final TextStyle titleStyle = GoogleFonts.poppins(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);
final TextStyle labelStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: Colors.black54,
);
final TextStyle buttonTextStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);
final TextStyle secondaryTextStyle = GoogleFonts.poppins(
  fontSize: 14,
  color: secondaryColor,
);

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = RoleManager.ROLE_USER;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        print('Starting registration process');
        final (user, error) = await _authService.register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          city: _cityController.text.trim(),
          username: _usernameController.text.trim(),
          role: _selectedRole,
        );

        print('Registration result: user=${user?.email}, error=$error');
        setState(() => _isLoading = false);
        if (user != null) {
          final (emailSent, emailError) = await _authService
              .sendEmailVerification(user);
          if (emailSent) {
            print('Showing verification dialog');
            showDialog(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cardBorderRadius),
                    ),
                    title: Text(
                      'Verification Email Sent',
                      style: titleStyle.copyWith(
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                    content: Text(
                      'A verification link has been sent to your email. Please verify to continue.',
                      style: secondaryTextStyle.copyWith(color: Colors.black54),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          'OK',
                          style: labelStyle.copyWith(color: primaryColor),
                        ),
                      ),
                    ],
                  ),
            );
          } else {
            print('Email verification failed: $emailError');
            _showErrorDialog(
              'Email Verification Failed',
              emailError ?? 'Unknown error',
            );
          }
        } else {
          print('Registration failed: $error');
          String errorMessage =
              error ?? 'Unable to register user. Please try again.';
          if (error != null && error.contains('permission-denied')) {
            errorMessage = 'Permission denied. Please check Firestore rules.';
          } else if (error != null &&
              (error.contains('network') || error.contains('timed out'))) {
            errorMessage =
                'Unable to connect to the server. Please check your internet or try again later.';
          } else if (error != null && error.contains('offline')) {
            errorMessage =
                'Operation queued offline. Please reconnect to sync data.';
          }
          _showErrorDialog('Registration Failed', errorMessage);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        print('Unexpected error in registration: $e');
        _showErrorDialog('Registration Failed', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    print('Showing error dialog: $title - $message');
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardBorderRadius),
            ),
            title: Text(
              title,
              style: titleStyle.copyWith(fontSize: 20, color: Colors.black87),
            ),
            content: Text(
              message,
              style: secondaryTextStyle.copyWith(color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'OK',
                  style: labelStyle.copyWith(color: primaryColor),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(defaultPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
              ), // Limite la largeur pour les grands écrans
              child: Card(
                elevation: cardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(cardBorderRadius),
                ),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: SizedBox(
                            width: 60, // Reduced size (adjust as needed)
                            height: 60, // Equal to width for a circle
                            child: ClipOval(
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/images/image.jpeg',
                                fit:
                                    BoxFit.cover, // Preserve image aspect ratio
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Titre
                        Text(
                          'Créer un compte',
                          style: titleStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Remplissez vos informations pour vous inscrire',
                          style: secondaryTextStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Champ Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                            labelStyle: labelStyle,
                            prefixIcon: Icon(
                              Icons.account_circle,
                              color: secondaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Veuillez entrer un nom d\'utilisateur'
                                      : null,
                          style: labelStyle.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        // Champ Ville
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'Ville',
                            labelStyle: labelStyle,
                            prefixIcon: Icon(
                              Icons.location_city,
                              color: secondaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: AuthValidators.validateCity,
                          style: labelStyle.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        // Champ Email
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: labelStyle,
                            prefixIcon: Icon(
                              Icons.email,
                              color: secondaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: AuthValidators.validateEmail,
                          style: labelStyle.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        // Champ Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: labelStyle,
                            prefixIcon: Icon(Icons.lock, color: secondaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: secondaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          obscureText: _obscurePassword,
                          validator: AuthValidators.validatePassword,
                          style: labelStyle.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        // Champ Confirmer Mot de passe
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            labelStyle: labelStyle,
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: secondaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: secondaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          obscureText: _obscureConfirmPassword,
                          validator:
                              (value) => AuthValidators.validateConfirmPassword(
                                value,
                                _passwordController.text,
                              ),
                          style: labelStyle.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        // Sélecteur de rôle
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Rôle',
                            labelStyle: labelStyle,
                            prefixIcon: Icon(
                              Icons.group,
                              color: secondaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: RoleManager.ROLE_USER,
                              child: Text(
                                'Utilisateur',
                                style: labelStyle.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: RoleManager.ROLE_ENTERPRISE,
                              child: Text(
                                'Entreprise',
                                style: labelStyle.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Veuillez sélectionner un rôle'
                                      : null,
                        ),
                        const SizedBox(height: 24),
                        // Bouton d'inscription
                        _isLoading
                            ? Column(
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Inscription en cours, veuillez patienter... (Mode hors ligne possible)',
                                  style: secondaryTextStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                            : ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    buttonBorderRadius,
                                  ),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'S\'inscrire',
                                style: buttonTextStyle,
                              ),
                            ),
                        const SizedBox(height: 24),
                        // Lien vers la connexion
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Vous avez déjà un compte ? ",
                              style: secondaryTextStyle,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed:
                                  () => Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  ),
                              child: Text(
                                'Connectez-vous',
                                style: secondaryTextStyle.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    _imageUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
