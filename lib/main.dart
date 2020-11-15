import 'dart:convert';
import 'dart:io';

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

  File _archivo;
  final _picker = ImagePicker();

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

  Future<File> obtenerValorDesencriptado() async {
    await initLlave();

    final encryptionKey =
        base64Url.decode(await secureStorage.read(key: 'key'));
    print('Encryption key: $encryptionKey');

    final encryptedBox = await Hive.openBox<File>('vaultBox',
        encryptionCipher: HiveAesCipher(encryptionKey));

    final pickedFile = await _picker.getVideo(source: ImageSource.gallery);
    _archivo = File(pickedFile.path);

    encryptedBox.put('secreto', _archivo);
    return encryptedBox.get('secreto');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: FutureBuilder<File>(
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Center(child: Text(snapshot.data.path));
            } else {
              return const CircularProgressIndicator();
            }
          },
          future: obtenerValorDesencriptado(),
        ));
  }
}
