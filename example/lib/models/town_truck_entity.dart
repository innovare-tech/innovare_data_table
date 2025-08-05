import 'package:innovare_data_table_example/models/active_inactive_status_enum.dart';

class TownTruck {
  final String id;
  final String organizationId;
  final String name;
  final String? document;
  final List<String> phones;
  final String? email;
  final String? city;
  final String? state;
  final String? zipCode;
  final String externalId;
  final ActiveInactiveStatus status;

  TownTruck({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.document,
    this.phones = const [],
    this.email,
    this.city,
    this.state,
    this.zipCode,
    required this.externalId,
    required this.status,
  });
}