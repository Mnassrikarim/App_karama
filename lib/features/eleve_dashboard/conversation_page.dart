import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:edu_karama_app/services/api_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ConversationPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String id;

  const ConversationPage({super.key, required this.userData, required this.id});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  late String? token;
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  Map<String, dynamic> otherUser = {};

  @override
  void initState() {
    super.initState();
    _loadTokenAndData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker(); // Initialize ImagePicker
  XFile? _selectedImage; // Store the selected image

  // New method to pick an image
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
        // Optionally, send the image immediately after picking
        await _sendMessage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la sélection de l\'image: $e')),
        );
      }
    }
  }

  Future<void> _loadTokenAndData() async {
    token = await ApiService.storage.read(key: 'jwt_token');
    if (token == null) {
      context.go('/login-eleve');
      return;
    }
    await _fetchTeacherData(); // Fetch teacher data first
    await _fetchConversation();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final config = {'Authorization': 'Bearer $token'};
      final response = await http.get(
        Uri.parse('https://kara-back.onrender.com/api/messages/teachers'),
        headers: config,
      );

      if (response.statusCode == 200) {
        final teacherData = jsonDecode(response.body) as List;
        if (teacherData.isNotEmpty && teacherData[0]['_id'] == widget.id) {
          setState(() {
            otherUser = {
              '_id': teacherData[0]['_id'],
              'nom': teacherData[0]['nom'],
              'prenom': teacherData[0]['prenom'],
              'role': teacherData[0]['__t'],
              'imageUrl':
                  'https://kara-back.onrender.com/Uploads/${teacherData[0]['imageUrl']}',
            };
          });
        }
      } else {
        throw Exception('Failed to load teacher data: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _fetchConversation() async {
    try {
      final config = {'Authorization': 'Bearer $token'};
      final response = await http.get(
        Uri.parse(
            'https://kara-back.onrender.com/api/messages/conversation/${widget.id}'),
        headers: config,
      );

      if (response.statusCode == 200) {
        final messageData = jsonDecode(response.body) as List;
        setState(() {
          messages = messageData.map<Map<String, dynamic>>((m) {
            final message = Map<String, dynamic>.from(m);
            final sender = Map<String, dynamic>.from(message['sender']);
            final recipient = Map<String, dynamic>.from(message['recipient']);

            // Format image URLs directly
            sender['imageUrl'] = sender['imageUrl'] != null &&
                    sender['imageUrl'].toString().isNotEmpty
                ? 'https://kara-back.onrender.com/${sender['imageUrl']}'
                : 'https://via.placeholder.com/40';
            recipient['imageUrl'] = recipient['imageUrl'] != null &&
                    recipient['imageUrl'].toString().isNotEmpty
                ? 'https://kara-back.onrender.com/${recipient['imageUrl']}'
                : 'https://via.placeholder.com/40';
            if (message['fileUrl'] != null &&
                message['fileUrl'].toString().isNotEmpty) {
              message['fileUrl'] =
                  'https://kara-back.onrender.com/${message['fileUrl'].toString().replaceFirst('/', '')}';
            }

            return {
              ...message,
              'sender': sender,
              'recipient': recipient,
            };
          }).toList();

          // Ensure otherUser is set if not already from _fetchTeacherData
          if (messages.isNotEmpty && otherUser.isEmpty) {
            final firstMessage = messages[0];
            final sender = Map<String, dynamic>.from(firstMessage['sender']);
            final recipient =
                Map<String, dynamic>.from(firstMessage['recipient']);

            if (sender['_id'] == widget.userData?['_id']) {
              otherUser = recipient;
            } else {
              otherUser = sender;
            }
            otherUser['imageUrl'] = otherUser['imageUrl'] != null &&
                    otherUser['imageUrl'].toString().isNotEmpty
                ? 'https://kara-back.onrender.com/Uploads/${otherUser['imageUrl']}'
                : 'https://via.placeholder.com/40';
          }

          loading = false;
        });
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => loading = false);
      }
    }
  }

  // Updated _sendMessage method to handle text and images
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _selectedImage == null) return; // Nothing to send

    setState(() => loading = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://kara-back.onrender.com/api/messages'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['recipientId'] = widget.id;
      if (content.isNotEmpty) {
        request.fields['content'] = content;
      }

      // Add image if selected
      if (_selectedImage != null) {
        final file = File(_selectedImage!.path);
        final mimeType = _selectedImage!.mimeType ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'file', // Adjust field name based on your backend API
            file.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Handle both single message and array of messages
        final List<dynamic> newMessages =
            responseData is List ? responseData : [responseData];

        final imageUrl = widget.userData?['imageUrl'];

        // Process each new message
        for (final newMessage in newMessages) {
          final messageToAdd = Map<String, dynamic>.from(newMessage);
          messageToAdd['sender'] = {
            '_id': widget.userData?['_id'],
            'prenom': widget.userData?['prenom'],
            'nom': widget.userData?['nom'],
            'role': widget.userData?['role'],
            'imageUrl': imageUrl != null && imageUrl.toString().isNotEmpty
                ? 'https://kara-back.onrender.com/$imageUrl'
                : 'https://via.placeholder.com/40',
          };
          messageToAdd['recipient'] = Map<String, dynamic>.from(otherUser);

          // If the message contains an image, format its URL
          if (messageToAdd['fileUrl'] != null &&
              messageToAdd['fileUrl'].toString().isNotEmpty) {
            messageToAdd['fileUrl'] = messageToAdd['fileUrl']
                    .toString()
                    .startsWith('/')
                ? 'https://kara-back.onrender.com/${messageToAdd['fileUrl'].toString().replaceFirst('/', '')}'
                : 'https://kara-back.onrender.com/${messageToAdd['fileUrl']}';
          }

          setState(() {
            messages.add(messageToAdd);
          });
        }

        setState(() {
          _messageController.clear();
          _selectedImage = null; // Clear the selected image
          loading = false;
        });
      } else {
        throw Exception(
            'Failed to send message: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => loading = false);
      }
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final sender = Map<String, dynamic>.from(message['sender']);
    final isSentByMe = sender['_id'] == widget.userData?['_id'];
    final senderName =
        isSentByMe ? 'Vous' : '${sender['prenom']} ${sender['nom']}';

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSentByMe ? Colors.blue[300] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12).copyWith(
            bottomRight: isSentByMe
                ? const Radius.circular(4)
                : const Radius.circular(12),
            bottomLeft: isSentByMe
                ? const Radius.circular(12)
                : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSentByMe ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Display image if fileUrl exists
            if (message['fileUrl'] != null &&
                message['fileUrl'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl:
                        '${message['fileUrl'].toString().replaceFirst('/', '')}',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            // Display text if content exists
            if (message['content']?.toString().isNotEmpty ?? false)
              Text(
                message['content'].toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: isSentByMe ? Colors.white : Colors.black,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              message['createdAt']?.toString().split('T')[1].split('.')[0] ??
                  '',
              style: TextStyle(
                fontSize: 10,
                color: isSentByMe ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/messages'),
          tooltip: 'Retour',
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                otherUser['imageUrl'] ?? 'https://via.placeholder.com/40',
              ),
              onBackgroundImageError: (exception, stackTrace) {
                print('Image loading error: $exception'); // Debug the error
              },
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${otherUser['prenom'] ?? 'Unknown'} ${otherUser['nom'] ?? 'User'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'En ligne',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: Colors.black),
            onPressed: () {
              // TODO: Implement photo functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessage(messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: _pickImage, // Call the new _pickImage method
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.mic, color: Colors.grey),
                  onPressed: () {
                    // TODO: Implement voice recording functionality
                  },
                ),
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  child: ElevatedButton(
                    onPressed: loading ? null : _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size(48, 48),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
