import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Constantes de design
const Color primaryColor = Color(0xFF00C853);
const Color errorColor = Color(0xFFD32F2F);
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

final TextStyle bodyStyle = GoogleFonts.poppins(fontSize: 14);

final TextStyle captionStyle = GoogleFonts.poppins(fontSize: 12);

final TextStyle buttonStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

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
      // Afficher un dialogue pour saisir le mot de passe
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
      // Réauthentification avec le mot de passe actuel
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Envoyer un email de vérification pour le nouvel email
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
