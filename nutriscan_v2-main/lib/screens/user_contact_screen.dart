import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

class UserContactScreen extends StatefulWidget {
  @override
  _UserContactScreenState createState() => _UserContactScreenState();
}

class _UserContactScreenState extends State<UserContactScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _showOnlyPending = false;

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

  void _showReplyDialog(String messageId) {
    final _formKey = GlobalKey<FormState>();
    final _replyController = TextEditingController();
    bool _isLoading = false;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: Text(
                    'Répondre au message',
                    style: subtitleStyle.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  content: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _replyController,
                          decoration: InputDecoration(
                            labelText: 'Votre réponse',
                            labelStyle: captionStyle.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
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
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Entrez une réponse';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
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
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                setDialogState(() => _isLoading = true);
                                try {
                                  // Récupérer le message pour obtenir userId
                                  final messageDoc =
                                      await FirebaseFirestore.instance
                                          .collection('messages')
                                          .doc(messageId)
                                          .get();
                                  if (!messageDoc.exists) {
                                    throw Exception('Message non trouvé');
                                  }
                                  final userId = messageDoc.data()!['userId'];

                                  // Mettre à jour /messages
                                  await FirebaseFirestore.instance
                                      .collection('messages')
                                      .doc(messageId)
                                      .update({
                                        'status': 'replied',
                                        'adminResponse':
                                            _replyController.text.trim(),
                                      });

                                  // Mettre à jour /users/{userId}/messages
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .collection('messages')
                                      .doc(messageId)
                                      .update({
                                        'status': 'replied',
                                        'adminResponse':
                                            _replyController.text.trim(),
                                      });

                                  _showSuccessSnackbar('Réponse envoyée');
                                  Navigator.of(ctx).pop();
                                } catch (e) {
                                  _showErrorSnackbar(
                                    'Erreur lors de l\'envoi de la réponse : $e',
                                  );
                                } finally {
                                  setDialogState(() => _isLoading = false);
                                }
                              },
                      child:
                          _isLoading
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Envoyer',
                                style: bodyStyle.copyWith(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            return Future.delayed(Duration(milliseconds: 500));
          },
          child: Padding(
            padding: EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Messages reçus',
                      style: headlineStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(
                        _showOnlyPending
                            ? Icons.filter_alt
                            : Icons.filter_alt_off,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      label: Text(
                        _showOnlyPending ? 'Tous' : 'En attente',
                        style: captionStyle.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showOnlyPending = !_showOnlyPending;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: itemSpacing),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('messages')
                            .where(
                              'status',
                              isEqualTo: _showOnlyPending ? 'sent' : null,
                            )
                            .orderBy('timestamp', descending: true)
                            .limit(20)
                            .snapshots(),
                    builder: (context, snapshot) {
                      print('Querying /messages');
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        print('Firestore error: ${snapshot.error}');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Erreur de chargement des messages',
                                style: bodyStyle.copyWith(color: errorColor),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => setState(() {}),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      buttonBorderRadius,
                                    ),
                                  ),
                                ),
                                child: Text('Réessayer', style: buttonStyle),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        print('No messages found in /messages');
                        return Center(
                          child: Text(
                            'Aucun message reçu',
                            style: bodyStyle.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        );
                      }

                      print('Messages loaded: ${snapshot.data!.docs.length}');
                      snapshot.data!.docs.forEach((doc) {
                        print('Message: ${doc.id} - ${doc.data()}');
                      });
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final messageData =
                              snapshot.data!.docs[index].data()
                                  as Map<String, dynamic>;
                          final messageId = snapshot.data!.docs[index].id;
                          return _buildMessageCard(messageData, messageId);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> messageData, String messageId) {
    final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
    final status = messageData['status'] ?? 'sent';
    final adminResponse = messageData['adminResponse'];

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
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child:
                      messageData['userImageUrl'] != null &&
                              messageData['userImageUrl'].isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: messageData['userImageUrl'],
                            imageBuilder:
                                (context, imageProvider) => CircleAvatar(
                                  radius: 20,
                                  backgroundImage: imageProvider,
                                ),
                            placeholder:
                                (context, url) => CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    primaryColor,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Icon(
                                  Icons.person,
                                  size: 20,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color,
                                ),
                          )
                          : Icon(
                            Icons.person,
                            size: 20,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                ),
                SizedBox(width: itemSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageData['username'] ?? 'Anonyme',
                        style: subtitleStyle.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      Text(
                        timestamp != null
                            ? timestamp.toString().substring(0, 16)
                            : 'N/A',
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
              messageData['content'] ?? '',
              style: bodyStyle.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            if (status == 'replied' && adminResponse != null) ...[
              SizedBox(height: itemSpacing),
              Text(
                'Votre réponse :',
                style: subtitleStyle.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                adminResponse,
                style: bodyStyle.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
            SizedBox(height: itemSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Statut : ${status == 'sent' ? 'En attente' : 'Répondu'}',
                  style: captionStyle.copyWith(
                    color: status == 'sent' ? errorColor : primaryColor,
                  ),
                ),
                Row(
                  children: [
                    if (status == 'sent')
                      ElevatedButton.icon(
                        icon: Icon(Icons.reply, size: 16),
                        label: Text('Répondre', style: captionStyle),
                        onPressed: () => _showReplyDialog(messageId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              buttonBorderRadius,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: errorColor,
                        size: 20,
                      ),
                      onPressed: () async {
                        try {
                          // Récupérer le message pour obtenir userId
                          final messageDoc =
                              await FirebaseFirestore.instance
                                  .collection('messages')
                                  .doc(messageId)
                                  .get();
                          if (!messageDoc.exists) {
                            throw Exception('Message non trouvé');
                          }
                          final userId = messageDoc.data()!['userId'];

                          // Supprimer de /messages
                          await FirebaseFirestore.instance
                              .collection('messages')
                              .doc(messageId)
                              .delete();

                          // Supprimer de /users/{userId}/messages
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('messages')
                              .doc(messageId)
                              .delete();

                          _showSuccessSnackbar('Message supprimé');
                        } catch (e) {
                          _showErrorSnackbar(
                            'Erreur lors de la suppression : $e',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
