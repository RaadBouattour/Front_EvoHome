class Device {
  final String id;
  final String name;
  final String type;
  bool state;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.state,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      state: json['state'],
    );
  }
}
