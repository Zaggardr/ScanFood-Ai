import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Constantes de design (réutilisées depuis user_contact_screen.dart)
const Color primaryColor = Color(0xFF00C853);
const Color errorColor = Color(0xFFD32F2F);
const double buttonBorderRadius = 8.0;
const double defaultPadding = 16.0;
const double cardElevation = 4.0;
const double cardBorderRadius = 12.0;
const double itemSpacing = 12.0;

// Styles de texte
final TextStyle bodyStyle = GoogleFonts.poppins(fontSize: 14);
final TextStyle buttonStyle = GoogleFonts.poppins(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);
final TextStyle subtitleStyle = GoogleFonts.poppins(fontSize: 16);
final TextStyle captionStyle = GoogleFonts.poppins(fontSize: 12);

class ContactScreen extends StatefulWidget {
  @override
  _ContactScreenState createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _messageController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _isLoading = false;

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

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'username': 'Anonyme', 'imageUrl': ''};

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      return {
        'username': data['username'] ?? user.displayName ?? 'Anonyme',
        'imageUrl': data['imageUrl'] ?? user.photoURL ?? '',
      };
    }
    return {
      'username': user.displayName ?? 'Anonyme',
      'imageUrl': user.photoURL ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Contacter l\'admin',
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
        ),
        body: Padding(
          padding: EdgeInsets.all(defaultPadding),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .limit(50)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('Firestore error: ${snapshot.error}');
                      return Center(
                        child: Text(
                          'Erreur de chargement des messages',
                          style: bodyStyle.copyWith(color: errorColor),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('No messages found for user ${user.uid}');
                      return Center(
                        child: Text(
                          'Aucun message envoyé',
                          style: bodyStyle.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    }

                    print('Messages loaded: ${snapshot.data!.docs.length}');
                    return ListView.builder(
                      reverse: true, // Nouveaux messages en bas
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
              SizedBox(height: itemSpacing),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Votre message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                style: bodyStyle,
                maxLines: 4,
              ),
              SizedBox(height: defaultPadding),
              ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          if (_messageController.text.trim().isEmpty) {
                            _showErrorSnackbar('Veuillez entrer un message');
                            return;
                          }
                          setState(() => _isLoading = true);
                          try {
                            final messageId =
                                FirebaseFirestore.instance
                                    .collection('messages')
                                    .doc()
                                    .id;
                            final userData = await _getCurrentUserData();
                            final messageData = {
                              'content': _messageController.text.trim(),
                              'timestamp': FieldValue.serverTimestamp(),
                              'userId': user!.uid,
                              'receiverId': 'admin', // ID de l'admin
                              'userImageUrl': userData['imageUrl'],
                              'username': userData['username'],
                              'status': 'sent',
                            };

                            // Écrire dans /messages
                            await FirebaseFirestore.instance
                                .collection('messages')
                                .doc(messageId)
                                .set(messageData);

                            // Écrire dans /users/{userId}/messages
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('messages')
                                .doc(messageId)
                                .set(messageData);

                            _showSuccessSnackbar('Message envoyé');
                            _messageController.clear();
                          } catch (e) {
                            _showErrorSnackbar('Erreur: $e');
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text('Envoyer', style: buttonStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> messageData, String messageId) {
    final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate();
    final status = messageData['status'] ?? 'sent';
    final adminResponse = messageData['adminResponse'];

    return Align(
      alignment: Alignment.centerRight, // Messages de l'utilisateur à droite
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Card(
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
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
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
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
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
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Text(
                            timestamp != null
                                ? timestamp.toString().substring(0, 16)
                                : 'N/A',
                            style: captionStyle.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
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
                    'Réponse de l\'admin :',
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
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: errorColor,
                        size: 20,
                      ),
                      onPressed: () async {
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            throw Exception('Utilisateur non connecté');
                          }

                          // Supprimer de /messages
                          await FirebaseFirestore.instance
                              .collection('messages')
                              .doc(messageId)
                              .delete();

                          // Supprimer de /users/{userId}/messages
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
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
          ),
        ),
      ),
    );
  }
}
