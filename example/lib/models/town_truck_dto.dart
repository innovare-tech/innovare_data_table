import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:innovare_data_table_example/models/active_inactive_status_enum.dart';

part 'town_truck_dto.g.dart';
part 'town_truck_dto.freezed.dart';

@unfreezed
sealed class TownTruckDTO with _$TownTruckDTO {
  factory TownTruckDTO({
    required String id,
    required String organizationId,
    required String name,
    String? document,
    @Default([]) List<String> phones,
    String? email,
    String? city,
    String? state,
    String? zipCode,
    required String externalId,
    @Default(ActiveInactiveStatus.active) ActiveInactiveStatus status,
  }) = _TownTruckDTO;

  factory TownTruckDTO.fromJson(Map<String, dynamic> json) => _$TownTruckDTOFromJson(json);
}