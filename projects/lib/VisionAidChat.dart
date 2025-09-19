import 'package:flutter/material.dart';
import 'package:projects/settings.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:projects/home_screen.dart';
import 'package:projects/ChatScreen.dart';
import 'dart:io';
import 'package:projects/services/auth_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'settings.dart';
import 'profile.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
final authService = AuthService();
class VisionAidChat extends StatefulWidget {
  @override
  _VisionAidChatState createState() => _VisionAidChatState();
}

class _VisionAidChatState extends State<VisionAidChat> {
  List<dynamic> _chatList = [];

  final TextEditingController _searchController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  int _selectedIndex = 1;

  @override
  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeAsync();  // Now context is safe to use
  });
  _speech = stt.SpeechToText();
}

Future<void> _initializeAsync() async {
  _chatList = await getChatList();
  setState(()  {
    _chatList = _chatList;
  }); // Update UI once data is fetched
}

  
  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    } else if(index == 1){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VisionAidChat()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
    }else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint('Speech status: $status'),
      onError: (error) => debugPrint('Speech error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        localeId: 'en_US', // Change to 'ar_AE' for Arabic
        onResult: (val) {
          setState(() {
            _searchController.text = val.recognizedWords;
          });
        },
      );
    } else {
      debugPrint('Speech recognition unavailable');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Speech recognition is not available")),
      );
    }
  }
  Future<List<dynamic>> getChatList() async {
  showDialog(
    context: context,
    builder: (_) => Center(child: CircularProgressIndicator()),
    barrierDismissible: false,
  );

  String? uri = dotenv.env['BACKEND'];
  if (uri == null) {
    print("!!!!!!!!!!!!!!!!!API not found");
    Navigator.pop(context); // Ensure we close the dialog
    return [];
  }
  String? uid = await authService.getCurrentUserId();
  print("________uid: $uid");
  final queryParams = {'to_uid': uid};
  final url = Uri.parse('$uri/list_chat').replace(queryParameters: queryParams);

  try {
    final response = await http.get(
      url
    );
    Navigator.pop(context); // Close the loading dialog

    if (response.statusCode == 200) {
      // Parse JSON response
      return jsonDecode(response.body);

      

    } else {
      print('Failed to fetch chat list: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error: $e');
    Navigator.pop(context); // Ensure dialog closes on error
    return [];
  }
}

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent, // made transparent to match uniform look
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          const SizedBox(width: 16),
          Text(
            'Chats',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.amberAccent,
            ),
          ),
        ],
      ),
      centerTitle: false,
      toolbarHeight: 80,
    ),

    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(255, 52, 32, 57)], // muted purple → charcoal
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: _startListening,
              child: AbsorbPointer(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.white70, fontSize: 20),
                    prefixIcon: Icon(Icons.search, color: Colors.white, size: 30),
                    filled: true,
                    fillColor: Color(0xFF75507B), // dimmed purple
                    contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: _chatList.isEmpty
                ? Center(
                    child: Text(
                      'No chats available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _chatList.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Colors.white24,
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD1A000), Color(0xFF9C6B00)], // gold → amber
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          leading: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.grey.shade300,
                            child: Icon(Icons.person, color: Colors.black, size: 36),
                          ),
                          title: Text(
                            _chatList[index]['name'],
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            _chatList[index]['created_at'],
                            style: TextStyle(fontSize: 18, color: Colors.white60),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatScreen(
                                      username: _chatList[index]['name']!,
                                      myname: _chatList[index]['my_name']!,
                                      fromUid: _chatList[index]['uid'],
                                      toUid: _chatList[index]['to_uid'],
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),

    bottomNavigationBar: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home
            Material(
              color: const Color(0xFFFFF8E1),
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () => _onItemTapped(0),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.home,
                    color: _selectedIndex == 0 ? Color(0xFF4A80B4) : Colors.black54,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Chat
            Material(
              color: const Color(0xFFFFF8E1),
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () => _onItemTapped(1),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.chat,
                    color: _selectedIndex == 1 ? Color(0xFF4A80B4) : Colors.black54,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Settings
            Material(
              color: const Color(0xFFFFF8E1),
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () => _onItemTapped(2),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Icon(
                    Icons.settings,
                    color: _selectedIndex == 2 ? Color(0xFF4A80B4) : Colors.black54,
                    size: 28,
                  ),
                ),
              ),
            ),
            // Avatar
            Material(
              color: const Color(0xFFFFF8E1),
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () => _onItemTapped(3),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/images/avatar.jpg'),
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
