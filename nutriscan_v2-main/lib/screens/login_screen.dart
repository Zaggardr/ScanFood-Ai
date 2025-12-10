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

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (user != null) {
          await user.reload();
          if (user.emailVerified) {
            // Vérifier le rôle de l'utilisateur
            String? role = await RoleManager.getUserRole(user);
            if (role == null) {
              _showErrorDialog('Role Error', 'No role assigned to this user.');
              return;
            }
            // Rediriger selon le rôle
            switch (role) {
              case RoleManager.ROLE_ADMIN:
                Navigator.pushReplacementNamed(context, '/scanner');

                break;
              case RoleManager.ROLE_ENTERPRISE:
                Navigator.pushReplacementNamed(context, '/scanner');
                break;
              case RoleManager.ROLE_USER:
              default:
                Navigator.pushReplacementNamed(context, '/scanner');
                break;
            }
          } else {
            _showErrorDialog(
              'Email not verified',
              'Please verify your email before logging in.',
            );
          }
        } else {
          _showErrorDialog('Login Failed', 'Invalid email or password.');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog('Login Failed', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
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
                        Center(
                          child: SizedBox(
                            width: 115, // Reduced size (adjust as needed)
                            height: 115, // Equal to width for a circle
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
                          'Bienvenue !',
                          style: titleStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous pour continuer',
                          style: secondaryTextStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 24),
                        // Bouton de connexion
                        _isLoading
                            ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                              ),
                            )
                            : ElevatedButton(
                              onPressed: _login,
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
                              child: Text('Connexion', style: buttonTextStyle),
                            ),
                        const SizedBox(height: 16),
                        // Mot de passe oublié
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed:
                                () => Navigator.pushNamed(context, '/reset'),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: secondaryTextStyle.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Inscription
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Pas de compte ? ", style: secondaryTextStyle),
                            TextButton(
                              onPressed:
                                  () =>
                                      Navigator.pushNamed(context, '/register'),
                              child: Text(
                                'Inscrivez-vous',
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
