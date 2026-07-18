// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 0;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      barcode: fields[1] as String,
      name: fields[2] as String,
      manufacturer: fields[3] as String,
      composition: fields[4] as String,
      dosage: fields[5] as String,
      expiration: fields[6] as String,
      requiresPrescription: fields[7] as bool,
      sideEffects: (fields[8] as List).cast<String>(),
      alternatives: (fields[9] as List).cast<String>(),
      isAuthentic: fields[10] as bool,
      risks: (fields[11] as List).cast<String>(),
      category: fields[12] as String,
      countryOrigin: fields[13] as String,
      imageUrl: fields[14] as String?,
      registrationNumber: fields[15] as String?,
      localizedNames: (fields[16] as Map).cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.barcode)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.manufacturer)
      ..writeByte(4)
      ..write(obj.composition)
      ..writeByte(5)
      ..write(obj.dosage)
      ..writeByte(6)
      ..write(obj.expiration)
      ..writeByte(7)
      ..write(obj.requiresPrescription)
      ..writeByte(8)
      ..write(obj.sideEffects)
      ..writeByte(9)
      ..write(obj.alternatives)
      ..writeByte(10)
      ..write(obj.isAuthentic)
      ..writeByte(11)
      ..write(obj.risks)
      ..writeByte(12)
      ..write(obj.category)
      ..writeByte(13)
      ..write(obj.countryOrigin)
      ..writeByte(14)
      ..write(obj.imageUrl)
      ..writeByte(15)
      ..write(obj.registrationNumber)
      ..writeByte(16)
      ..write(obj.localizedNames);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScanResultAdapter extends TypeAdapter<ScanResult> {
  @override
  final int typeId = 1;

  @override
  ScanResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanResult(
      id: fields[0] as String,
      scannedCode: fields[1] as String,
      scanType: fields[2] as ScanType,
      product: fields[3] as ProductModel?,
      scannedAt: fields[4] as DateTime,
      isAuthentic: fields[5] as bool,
      location: fields[6] as String?,
      wasReported: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ScanResult obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scannedCode)
      ..writeByte(2)
      ..write(obj.scanType)
      ..writeByte(3)
      ..write(obj.product)
      ..writeByte(4)
      ..write(obj.scannedAt)
      ..writeByte(5)
      ..write(obj.isAuthentic)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.wasReported);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScanTypeAdapter extends TypeAdapter<ScanType> {
  @override
  final int typeId = 2;

  @override
  ScanType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScanType.barcode;
      case 1:
        return ScanType.qrCode;
      case 2:
        return ScanType.ocr;
      case 3:
        return ScanType.manual;
      default:
        return ScanType.barcode;
    }
  }

  @override
  void write(BinaryWriter writer, ScanType obj) {
    switch (obj) {
      case ScanType.barcode:
        writer.writeByte(0);
        break;
      case ScanType.qrCode:
        writer.writeByte(1);
        break;
      case ScanType.ocr:
        writer.writeByte(2);
        break;
      case ScanType.manual:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
