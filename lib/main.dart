import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const NoticeBoard());
}

// Data Models
class Message {
  final String text;
  final String? fileName;
  final DateTime timestamp;
  final File? file;
  final String sender;

  Message({
    required this.text,
    this.fileName,
    required this.timestamp,
    this.file,
    required this.sender,
  });
}

class PrivateChat {
  final String originalMessage;
  final String participant1;
  final String participant2;
  final List<Message> messages;
  final DateTime createdAt;

  PrivateChat({
    required this.originalMessage,
    required this.participant1,
    required this.participant2,
    required this.messages,
    required this.createdAt,
  });
}

// Main App
class NoticeBoard extends StatelessWidget {
  const NoticeBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notice Board',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NoticeBoardHome(),
    );
  }
}

// Home Screen
class NoticeBoardHome extends StatefulWidget {
  const NoticeBoardHome({super.key});

  @override
  State<NoticeBoardHome> createState() => _NoticeBoardHomeState();
}

class _NoticeBoardHomeState extends State<NoticeBoardHome> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final List<PrivateChat> _privateChats = [];
  File? _selectedFile;
  String? _selectedFileName;
  final ImagePicker _imagePicker = ImagePicker();
  final String currentUser = 'Student 1'; // Simulating logged in user

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _selectedFileName = image.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty || _selectedFile != null) {
      setState(() {
        _messages.add(Message(
          text: _messageController.text,
          fileName: _selectedFileName,
          timestamp: DateTime.now(),
          file: _selectedFile,
          sender: currentUser,
        ));
        _messageController.clear();
        _selectedFile = null;
        _selectedFileName = null;
      });
    }
  }

  void _navigateToPrivateChats() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivateChatsScreen(chats: _privateChats)),
    );
  }

  void _startPrivateChat(Message originalMessage) {
    // Check if chat already exists
    final existingChat = _privateChats.firstWhere(
      (chat) => chat.originalMessage == originalMessage.text &&
          (chat.participant1 == currentUser || chat.participant2 == currentUser),
      orElse: () => PrivateChat(
        originalMessage: originalMessage.text,
        participant1: currentUser,
        participant2: originalMessage.sender,
        messages: [],
        createdAt: DateTime.now(),
      ),
    );

    if (!_privateChats.contains(existingChat)) {
      setState(() {
        _privateChats.add(existingChat);
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatScreen(
          chat: existingChat,
          currentUser: currentUser,
          onMessageSent: (message) {
            setState(() {
              existingChat.messages.add(message);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: _navigateToPrivateChats,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              message.sender,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${message.timestamp.hour}:${message.timestamp.minute}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(message.text),
                        if (message.file != null) ...[
                          const SizedBox(height: 8),
                          if (message.fileName!.toLowerCase().endsWith('.jpg') ||
                              message.fileName!.toLowerCase().endsWith('.png'))
                            Image.file(
                              message.file!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          else
                            Row(
                              children: [
                                const Icon(Icons.attach_file),
                                const SizedBox(width: 8),
                                Text(message.fileName!),
                              ],
                            ),
                        ],
                        if (message.sender != currentUser)
                          TextButton.icon(
                            icon: const Icon(Icons.reply),
                            label: const Text('Reply Privately'),
                            onPressed: () => _startPrivateChat(message),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_selectedFileName!)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                              _selectedFileName = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () => _showAttachmentOptions(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_present),
            title: const Text('Pick Document'),
            onTap: () {
              Navigator.pop(context);
              _pickDocument();
            },
          ),
        ],
      ),
    );
  }
}

// Private Chats List Screen
class PrivateChatsScreen extends StatelessWidget {
  final List<PrivateChat> chats;

  const PrivateChatsScreen({super.key, required this.chats});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Chats'),
      ),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;

          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(chat.participant2),
            subtitle: Text(
              lastMessage?.text ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              lastMessage != null
                  ? '${lastMessage.timestamp.hour}:${lastMessage.timestamp.minute}'
                  : '',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivateChatScreen(
                    chat: chat,
                    currentUser: 'Student 1',
                    onMessageSent: (message) {
                      chat.messages.add(message);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Private Chat Screen
class PrivateChatScreen extends StatefulWidget {
  final PrivateChat chat;
  final String currentUser;
  final Function(Message) onMessageSent;

  const PrivateChatScreen({
    super.key,
    required this.chat,
    required this.currentUser,
    required this.onMessageSent,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedFile;
  String? _selectedFileName;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
          _selectedFileName = image.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty || _selectedFile != null) {
      final message = Message(
        text: _messageController.text,
        fileName: _selectedFileName,
        timestamp: DateTime.now(),
        file: _selectedFile,
        sender: widget.currentUser,
      );
      widget.onMessageSent(message);
      setState(() {
        _messageController.clear();
        _selectedFile = null;
        _selectedFileName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.participant2),
      ),
      body: Column(
        children: [
          // Original message reference
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[200],
            child: Row(
              children: [
                const Icon(Icons.reply),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Original post: ${widget.chat.originalMessage}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.chat.messages.length,
              itemBuilder: (context, index) {
                final message = widget.chat.messages[index];
                final bool isCurrentUser = message.sender == widget.currentUser;

                return Align(
                  alignment:
                      isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.text),
                        if (message.file != null) ...[
                          const SizedBox(height: 8),
                          if (message.fileName!.toLowerCase().endsWith('.jpg') ||
                              message.fileName!.toLowerCase().endsWith('.png'))
                            Image.file(
                              message.file!,
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover 
                                         )
                                        else
            Row(
              children: [
                const Icon(Icons.attach_file),
                const SizedBox(width: 8),
                Text(message.fileName!),
              ],
            ),
        ],
        const SizedBox(height: 4),
        Text(
          '${message.timestamp.hour}:${message.timestamp.minute}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_selectedFileName!)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                              _selectedFileName = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () => _showAttachmentOptions(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_present),
            title: const Text('Pick Document'),
            onTap: () {
              Navigator.pop(context);
              _pickDocument();
            },
          ),
        ],
      ),
    );
  }
}                                                      
                              
                              
         