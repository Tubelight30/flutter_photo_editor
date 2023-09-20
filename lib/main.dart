import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photoeditor/constants/constants.dart';
import 'package:image/image.dart' as img;
import 'package:photoeditor/utils/show_dialogue.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Editor App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Image Editor App',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? originalImageData;
  Uint8List? imageData;
  int flag = 0;

  @override
  void initState() {
    super.initState();
    loadAsset(AssetsConstants.placeholderLogo);
  }

  Future<Uint8List?> applyFilter(Uint8List? imageBytes) async {
    if (imageBytes == null) return null;

    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;
    final grayscaleImage =
        img.grayscale(originalImage); // Apply grayscale filter

    return Uint8List.fromList(img.encodeJpg(grayscaleImage));
  }

  Future<void> saveEditedImage(Uint8List editedImageData) async {
    try {
      final appDocDir = await getExternalStorageDirectory();
      final filePath = '${appDocDir!.path}/edited_image.png';
      final file = File(filePath);
      await file.writeAsBytes(editedImageData);
      //if (mounted)
      showDialogBox(context, 'Image saved successfully to $filePath');
    } on Exception catch (e) {
      showDialogBox(context, "Image not saved: $e");
    }
  }

  void loadAsset(String name) async {
    var data = await rootBundle.load(name);
    setState(
      () {
        imageData = data.buffer.asUint8List();
      },
    );
  }

  Future getImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source);
    if (image == null) return;

    final imageTemporary = File(image.path);
    setState(
      () {
        flag = 1;
        originalImageData = imageTemporary.readAsBytesSync();
        imageData = imageTemporary.readAsBytesSync();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: <Widget>[
                imageData != null
                    ? SizedBox(
                        height: 300,
                        width: 300,
                        child: Image.memory(imageData!),
                      )
                    : SizedBox(
                        height: 300,
                        width: 300,
                        child: Image.asset('assets/images/Screenshot.png'),
                      ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton.icon(
                  onPressed: () => {
                    getImage(ImageSource.gallery),
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Image From Gallery"),
                ),
                ElevatedButton.icon(
                  onPressed: () => {
                    getImage(ImageSource.camera),
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Image From Camera"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            if (flag != 1) {
                              throw Exception("Please select an image first");
                            }
                            final editedImage = await applyFilter(imageData);
                            if (editedImage != null) {
                              setState(
                                () {
                                  imageData = editedImage;
                                },
                              );
                            }
                          } catch (e) {
                            showDialogBox(context, "$e");
                          }
                        },
                        child: const Text("Apply Filter"),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            if (flag != 1) {
                              throw Exception("Please select an image first");
                            }
                            var editedImage = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageEditor(
                                  image: imageData,
                                ),
                              ),
                            );
                            if (editedImage != null) {
                              imageData = editedImage;
                              setState(() {});
                            }
                          } catch (e) {
                            showDialogBox(context, "$e");
                          }
                        },
                        child: const Text("Image editor"),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            const Color.fromARGB(255, 133, 214, 230),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            if (flag != 1) {
                              throw Exception("Please select an image first");
                            }
                            await saveEditedImage(imageData!);
                          } catch (e) {
                            showDialogBox(context, "$e");
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      margin: const EdgeInsets.all(10),
                      child: ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Color.fromARGB(255, 241, 86, 34))),
                        onPressed: () {
                          try {
                            if (flag != 1) {
                              throw Exception("Please select an image first");
                            }
                            imageData = originalImageData;
                            setState(() {});
                          } catch (e) {
                            showDialogBox(context, "$e");
                          }
                        },
                        child: const Text("Reset all changes"),
                      ),
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
