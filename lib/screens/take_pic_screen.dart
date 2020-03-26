import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pPath;
import 'package:provider/provider.dart';
import '../models/picture.dart';
import '../providers/pictures.dart';
import 'package:exif/exif.dart';

class TakePicScreen extends StatefulWidget {
  static const routeName = '/take-pic';

  @override
  _TakePicScreenState createState() => _TakePicScreenState();
}

class _TakePicScreenState extends State<TakePicScreen> {
  File _takenImage;
  bool _imgHasLocation = false;
  GeoFirePoint _imgLocation;

  
  Future<void> _takePicture() async {
    final imageFile = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    Map<String, IfdTag> imgTags = await readExifFromBytes(imageFile.readAsBytesSync());

    if (imgTags.containsKey('GPS GPSLongitude')) {
      setState(() {
        _imgHasLocation = true;
        _imgLocation = exifGPSToGeoFirePoint(imgTags);
      });
    }

    if (imageFile == null) {
      return;
    }
    setState(() {
      _takenImage = imageFile;
    });
    final appDir = await pPath.getApplicationDocumentsDirectory();
    final fileName = path.basename(imageFile.path);
    final savedImage = await imageFile.copy('${appDir.path}/$fileName');

    var _imageToStore = Picture(picName: savedImage);
    _storeImage() {
      Provider.of<Pictures>(context, listen: false).storeImage(_imageToStore);
    }

    _storeImage();
  }

  GeoFirePoint exifGPSToGeoFirePoint(Map<String, IfdTag> tags) {

  final latitudeValue = tags['GPS GPSLatitude'].values.map<double>( (item) => (item.numerator.toDouble() / item.denominator.toDouble()) ).toList();
  final latitudeSignal = tags['GPS GPSLatitudeRef'].printable;


  final longitudeValue = tags['GPS GPSLongitude'].values.map<double>( (item) => (item.numerator.toDouble() / item.denominator.toDouble()) ).toList();
  final longitudeSignal = tags['GPS GPSLongitudeRef'].printable;

  double latitude = latitudeValue[0]
    + (latitudeValue[1] / 60)
    + (latitudeValue[2] / 3600);

  double longitude = longitudeValue[0]
    + (longitudeValue[1] / 60)
    + (longitudeValue[2] / 3600);

  if (latitudeSignal == 'S') latitude = -latitude;
  if (longitudeSignal == 'W') longitude = -longitude;

  print('COORDENADAS DA IMAGEM DA GALERIA =>>>>>>>>>>>> Lat: $latitude // Lng: $longitude');

  return  GeoFirePoint(latitude, longitude);
}

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: FlatButton.icon(
          icon: Icon(
            Icons.photo_camera,
            size: 100,
          ),
          label: Text(''),
          textColor: Theme.of(context).primaryColor,
          onPressed: _takePicture,
        ),
      ),
    );
  }
}
