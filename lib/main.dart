import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dithering',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // String urlFotoSite = 'https://bestlatinawomen.com';
  // String urlFotoFile = '/wp-content/uploads/2020/04/brazil1.jpg';

  String urlFotoSite = 'https://b.thumbs.redditmedia.com';
  String urlFotoFile = '/bjwsUJPh0C0eueuaq0trJ1U8UOuoZ8op38tnHJNejgE.png';

  Uint8List bytes;
  Uint8List bytesNew;
  img.Image imagem;

  int abgrToArgb(int argbColor) {
    int r = (argbColor >> 16) & 0xFF;
    int b = argbColor & 0xFF;
    return (argbColor & 0xFF00FF00) | (b << 16) | r;
  }

  Future load(String urlSite, String urlFoto) async {
    NetworkAssetBundle netAsset = NetworkAssetBundle(Uri.parse(urlSite));
    ByteData byteData = await netAsset.load(urlFoto);
    Uint8List bytes = byteData.buffer.asUint8List();
    imagem = img.decodeImage(bytes);
    // dither();
    return bytes;
  }

  void dither() async {
    int pixel;
    int erro;
    Color c;
    imagem = greyScale(imagem);
    for (int x = 0; x <= imagem.width - 1; x++) {
      for (int y = 0; y <= imagem.height - 1; y++) {
        pixel = imagem.getPixel(x, y);
        c = Color(pixel);
        c = filter(c);
        erro = greyError(Color(pixel), c);
        imagem.setPixel(x, y, c.value);

        // dispersao de erro:
        if (x < imagem.width - 1) {
          pixel = imagem.getPixel(x + 1, y);
          imagem.setPixel(x + 1, y, setaErro(pixel, erro, 7 / 16)); // 7/16
        }

        if (y < imagem.height - 1) {
          if (x > 0) {
            pixel = imagem.getPixel(x - 1, y + 1);
            imagem.setPixel(
                x - 1, y + 1, setaErro(pixel, erro, 3 / 16)); // 3/16
          }

          pixel = imagem.getPixel(x, y + 1);
          imagem.setPixel(x, y + 1, setaErro(pixel, erro, 5 / 16)); //  5/16

          if (x < imagem.width - 1) {
            pixel = imagem.getPixel(x + 1, y + 1);
            imagem.setPixel(
                x + 1, y + 1, setaErro(pixel, erro, 1 / 16)); //  1/16
          }
        }
      }
    }
    img.PngEncoder png = img.PngEncoder();
    List<int> temp = png.encodeImage(imagem);
    setState(() => bytesNew = temp);
  }

  int setaErro(int pixel, int erro, double proporcaoErro) {
    Color c = Color(pixel);
    int err = (erro * proporcaoErro).round();
    int red = c.red + err;
    int green = c.green + err;
    int blue = c.blue + err;
    if (red > 255) red = 255;
    if (blue > 255) blue = 255;
    if (green > 255) green = 255;
    if (red < 0) red = 0;
    if (green < 0) green = 0;
    if (blue < 0) blue = 0;
    c = Color.fromARGB(255, red, green, blue);
    return c.value;
  }

  img.Image greyScale(img.Image imagem) {
    Color cor;
    int grey;
    for (int y = 0; y <= imagem.height - 1; y++)
      for (int x = 0; x <= imagem.width - 1; x++) {
        cor = Color(imagem.getPixel(x, y));
        grey = (cor.red + cor.green + cor.blue) ~/ 3;
        imagem.setPixel(x, y, Color.fromARGB(255, grey, grey, grey).value);
      }
    return imagem;
  }

  int greyError(Color newColor, Color oldColor) {
    return newColor.red - oldColor.red;
  }

  Color filter(Color cor, [int levels = 2]) {
    int r = cor.red;
    int g = cor.green;
    int b = cor.blue;
    r = ((levels - 1) * cor.red / 255).round() * 255 ~/ (levels - 1);
    g = ((levels - 1) * cor.green / 255).round() * 255 ~/ (levels - 1);
    b = ((levels - 1) * cor.blue / 255).round() * 255 ~/ (levels - 1);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  void initState() {
    super.initState();
    load(urlFotoSite, urlFotoFile).then((value) {
      print('carreguei');
      setState(() => bytes = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dithering'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            bytes != null ? Image.memory(bytes) : CircularProgressIndicator(),
            SizedBox(height: 20),
            Center(
              child: bytesNew != null
                  ? Image.memory(bytesNew)
                  : CircularProgressIndicator(),
            ),
            ElevatedButton(child: Text('Dither'), onPressed: dither),
          ],
        ),
      ),
    );
  }
}
