import 'package:flutter/material.dart';

class DeviceModel {
  final String id;
  final String name;
  final String type;
  final String
  status; // 'Connected' | 'Online' | 'Active' | 'Warning' | 'Offline'
  final String lastSynced;
  final String firmwareVersion;
  final String latestFirmwareVersion;
  final String deviceId;
  final String serialNumber;
  final String lastConnected;
  final int batteryStatus; // -1 for plugged in, 0-100 for battery percentage
  final int wifiSignal; // 0-100 signal strength
  final String signalQuality; // 'Excellent' | 'Good' | 'Poor' | 'N/A'
  final String description;
  final bool hdReady;
  final String? currentValue;
  final String connectedNetwork;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.lastSynced,
    required this.firmwareVersion,
    required this.latestFirmwareVersion,
    required this.deviceId,
    required this.serialNumber,
    required this.lastConnected,
    required this.batteryStatus,
    required this.wifiSignal,
    required this.signalQuality,
    required this.description,
    this.hdReady = false,
    this.currentValue,
    this.connectedNetwork = 'Maatriva_Nursery_5G',
  });

  bool get isConnected =>
      status == 'Connected' || status == 'Online' || status == 'Active';
  bool get hasFirmwareUpdate => firmwareVersion != latestFirmwareVersion;

  DeviceModel copyWith({
    String? id,
    String? name,
    String? type,
    String? status,
    String? lastSynced,
    String? firmwareVersion,
    String? latestFirmwareVersion,
    String? deviceId,
    String? serialNumber,
    String? lastConnected,
    int? batteryStatus,
    int? wifiSignal,
    String? signalQuality,
    String? description,
    bool? hdReady,
    String? currentValue,
    String? connectedNetwork,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      lastSynced: lastSynced ?? this.lastSynced,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      latestFirmwareVersion:
          latestFirmwareVersion ?? this.latestFirmwareVersion,
      deviceId: deviceId ?? this.deviceId,
      serialNumber: serialNumber ?? this.serialNumber,
      lastConnected: lastConnected ?? this.lastConnected,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      wifiSignal: wifiSignal ?? this.wifiSignal,
      signalQuality: signalQuality ?? this.signalQuality,
      description: description ?? this.description,
      hdReady: hdReady ?? this.hdReady,
      currentValue: currentValue ?? this.currentValue,
      connectedNetwork: connectedNetwork ?? this.connectedNetwork,
    );
  }
}
