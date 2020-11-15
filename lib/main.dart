import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar hive
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final picker = ImagePicker();
  final llave = "llave";
  final nombreBox = "archivosEncriptados";

  @override
  void initState() {
    super.initState();
  }

  Future<void> initLlave() async {
    final containsEncryptionKey = await secureStorage.containsKey(key: 'key');
    if (!containsEncryptionKey) {
      var key = Hive.generateSecureKey();
      await secureStorage.write(key: 'key', value: base64UrlEncode(key));
    }
  }

  Future<Box<Uint8List>> _obtenerBoxDesencriptado() async {
    await initLlave();

    final encryptionKey =
        base64Url.decode(await secureStorage.read(key: 'key'));

    return Hive.openBox<Uint8List>(nombreBox,
        encryptionCipher: HiveAesCipher(encryptionKey));
  }

  void _agregarImagen() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    final archivo = File(pickedFile.path);
    final bytes = await archivo.readAsBytes();

    final encryptedBox = await _obtenerBoxDesencriptado();
    encryptedBox.put(llave, bytes);

    setState(() {});
  }

  Future<Widget> _obtenerImagen() async {
    final encryptedBox = await _obtenerBoxDesencriptado();
    final dir = await getApplicationDocumentsDirectory();

    if (encryptedBox.containsKey(llave)) {
      final bytes = encryptedBox.get(llave);

      final file = File(dir.path + "/archivo");
      await file.writeAsBytes(bytes);

      return Image.file(file);
    } else {
      return const Text("No hay imagen");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            RaisedButton(
              child: const Text("Agregar imagen"),
              onPressed: _agregarImagen,
            ),
            FutureBuilder<Widget>(
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return snapshot.data;
                } else {
                  return const CircularProgressIndicator();
                }
              },
              future: _obtenerImagen(),
            )
          ],
        ));
  }
}
