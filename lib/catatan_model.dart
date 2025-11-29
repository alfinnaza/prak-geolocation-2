import 'dart:convert';

import 'package:latlong2/latlong.dart';

class CatatanModel {
  final LatLng position;
  final String note;
  final String address;
  final String type;

  CatatanModel({
    required this.position,
    required this.note,
    required this.address,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      "lat": position.latitude,
      "lng": position.longitude,
      "note": note,
      "address": address,
      "type": type,
    };
  }

  factory CatatanModel.fromMap(Map<String, dynamic> map) {
    return CatatanModel(
      position: LatLng(map["lat"], map["lng"]),
      note: map["note"],
      address: map["address"],
      type: map["type"],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory CatatanModel.fromJson(String source) => CatatanModel.fromMap(jsonDecode(source));
}