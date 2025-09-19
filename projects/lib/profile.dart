import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';

AuthService authService = AuthService();
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  String _location = "Loading...";
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to access image: \$e")),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionButton(
                  icon: Icons.camera_alt,
                  label: "Camera",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildOptionButton(
                  icon: Icons.photo_library,
                  label: "Gallery",
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(icon, size: 30, color: Color(0xFF0F3460)),
          ),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location permission denied")),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location permissions are permanently denied")),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          _location = placemarks.first.locality ?? "Unknown";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      print("Error getting location: \$e");
    }
  }

  void _showLocationActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Share Location",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: Icon(Icons.copy, color: Colors.white),
              label: Text(
                "Copy to Clipboard",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _location));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Location copied to clipboard")),
                );
              },
            ),
            SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: Icon(Icons.send, color: Colors.white),
              label: Text(
                "Send to Chat",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chat', arguments: _location);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.yellow),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.yellow,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        if (title == "Send my location") {
          _showLocationActionSheet();
        } else if (title == "Emergency Contact") {
          _handleEmergencyContact();
        } else if (title == "Settings"){
          Navigator.pushNamed(context, '/settings');

        }
      },
    );
  }

  Future<void> _handleEmergencyContact() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FutureBuilder<EmergencyContact?>(
        future: ApiService.fetchEmergencyContact(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            final contact = snapshot.data!;
            return AlertDialog(
              title: Text('Emergency Contact'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${contact.name}'),
                  SizedBox(height: 8),
                  Text('Phone: ${contact.phone}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Text('No contacts'),
              content: Text('You have no emergency contacts.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddContactForm();
                  },
                  child: Text('Add Contact'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _showAddContactForm() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add Emergency Contact'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => name = value!.trim(),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => phone = value!.trim(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                Navigator.pop(context);
                await ApiService.addEmergencyContact(
                    EmergencyContact(name: name, phone: phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Contact saved')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xdd04003d),
      body: SafeArea(
        
        child: SingleChildScrollView(      // make the entire page scrollable when keyboard appears
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child:Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
            ),
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? Icon(Icons.person, size: 50, color: Colors.black)
                    : null,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Username",
              style: TextStyle(
                fontSize: 30,
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 24),
                SizedBox(width: 4),
                _isLoadingLocation
                    ? SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(_location, style: TextStyle(color: Colors.white)),
              ],
            ),
            Divider(color: Colors.grey.shade600, height: 30),
            _buildMenuItem(Icons.person, "Personal Information"),
            SizedBox(height: 15),
            _buildMenuItem(Icons.settings, "Settings"),
            SizedBox(height: 15),
            _buildMenuItem(Icons.language, "Send my location"),
            SizedBox(height: 15),
            _buildMenuItem(Icons.warning, "Emergency Contact"),
            
          ],
        ),
      ),
      ),
    );
  }
}

/// Simple model for emergency contact
class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({required this.name, required this.phone});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
      };
}
String? url = dotenv.env['BACKEND'];
/// API service for fetching and adding emergency contacts
class ApiService {
  
  static Future<EmergencyContact?> fetchEmergencyContact() async {
    final uid = await authService.getCurrentUserId();
    if (uid == null) {
      print("!!!!!Error: User ID is null");
      return null;
    }
    final queryParams = {'uid': uid};
    final response = await http.get(Uri.parse('$url/emergency_info').replace(queryParameters: queryParams));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['name'] != null) {
        return EmergencyContact.fromJson(data);
      }
    }
    return null;
  }


  static Future<bool> addEmergencyContact(EmergencyContact contact) async {
    final uid = await authService.getCurrentUserId();
    if (uid == null) {
      print("!!!!!Error: User ID is null");
      return false;
    }
    final request = http.MultipartRequest('POST', Uri.parse('$url/emergency_info'))
      ..fields['name'] = contact.name
      ..fields['phone'] = contact.phone
      ..fields['uid'] = uid;
    final response = await request.send();
     
    return response.statusCode == 201;
  }
}
