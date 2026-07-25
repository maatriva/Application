import 'package:equatable/equatable.dart';

/// Representation of a Smart Device model for the UI and state management.
class DeviceModel extends Equatable {
  final String id;
  final String name;
  final String type;
  final String status; // 'Connected' | 'Online' | 'Active' | 'Warning' | 'Offline'
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
  final String? babyId;

  const DeviceModel({
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
    this.babyId,
  });

  bool get isConnected =>
      status == 'Connected' || status == 'Online' || status == 'Active';
  bool get hasFirmwareUpdate => firmwareVersion != latestFirmwareVersion;

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'Offline',
      lastSynced: json['lastSynced'] as String? ?? '',
      firmwareVersion: json['firmwareVersion'] as String? ?? '1.0.0',
      latestFirmwareVersion: json['latestFirmwareVersion'] as String? ?? '1.0.0',
      deviceId: json['deviceId'] as String? ?? '',
      serialNumber: json['serialNumber'] as String? ?? '',
      lastConnected: json['lastConnected'] as String? ?? '',
      batteryStatus: json['batteryStatus'] as int? ?? -1,
      wifiSignal: json['wifiSignal'] as int? ?? 0,
      signalQuality: json['signalQuality'] as String? ?? 'N/A',
      description: json['description'] as String? ?? '',
      hdReady: json['hdReady'] as bool? ?? false,
      currentValue: json['currentValue'] as String?,
      connectedNetwork: json['connectedNetwork'] as String? ?? 'Maatriva_Nursery_5G',
      babyId: json['babyId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'lastSynced': lastSynced,
      'firmwareVersion': firmwareVersion,
      'latestFirmwareVersion': latestFirmwareVersion,
      'deviceId': deviceId,
      'serialNumber': serialNumber,
      'lastConnected': lastConnected,
      'batteryStatus': batteryStatus,
      'wifiSignal': wifiSignal,
      'signalQuality': signalQuality,
      'description': description,
      'hdReady': hdReady,
      if (currentValue != null) 'currentValue': currentValue,
      'connectedNetwork': connectedNetwork,
      if (babyId != null) 'babyId': babyId,
    };
  }

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
    String? babyId,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      lastSynced: lastSynced ?? this.lastSynced,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      latestFirmwareVersion: latestFirmwareVersion ?? this.latestFirmwareVersion,
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
      babyId: babyId ?? this.babyId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        status,
        lastSynced,
        firmwareVersion,
        latestFirmwareVersion,
        deviceId,
        serialNumber,
        lastConnected,
        batteryStatus,
        wifiSignal,
        signalQuality,
        description,
        hdReady,
        currentValue,
        connectedNetwork,
        babyId,
      ];
}
