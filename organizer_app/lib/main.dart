import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() => runApp(const OrganizerApp());

class OrganizerApp extends StatelessWidget {
  const OrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblioteca Color Sorter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const BibliotecaHomePage(),
    );
  }
}

class BibliotecaHomePage extends StatefulWidget {
  const BibliotecaHomePage({super.key});

  @override
  State<BibliotecaHomePage> createState() => _BibliotecaHomePageState();
}

class _BibliotecaHomePageState extends State<BibliotecaHomePage> {
  File? _image;
  List<Color> sortedColors = [];
  bool loading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        sortedColors.clear();
      });
      await _processImage(_image!);
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => loading = true);

    final uri = Uri.parse('http://10.0.2.2:5000/analyze'); // schimbă cu IP real dacă e nevoie
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(respStr);
      setState(() {
        sortedColors = (data['colors'] as List)
            .map((c) => Color.fromRGBO(c[0], c[1], c[2], 1))
            .toList();
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca după culoare')),
      body: Center(
        child: loading
            ? const SpinKitFadingCircle(color: Colors.deepOrange)
            : _image == null
                ? const Text('Fă o poză la biblioteca ta 📸')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.file(_image!, height: 200),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 5,
                          children: sortedColors
                              .map((c) => Container(color: c))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
