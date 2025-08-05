// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'town_truck_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TownTruckDTO _$TownTruckDTOFromJson(Map<String, dynamic> json) =>
    _TownTruckDTO(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      name: json['name'] as String,
      document: json['document'] as String?,
      phones: (json['phones'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      email: json['email'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      externalId: json['externalId'] as String,
      status:
          $enumDecodeNullable(_$ActiveInactiveStatusEnumMap, json['status']) ??
              ActiveInactiveStatus.active,
    );

Map<String, dynamic> _$TownTruckDTOToJson(_TownTruckDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organizationId': instance.organizationId,
      'name': instance.name,
      'document': instance.document,
      'phones': instance.phones,
      'email': instance.email,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'externalId': instance.externalId,
      'status': _$ActiveInactiveStatusEnumMap[instance.status]!,
    };

const _$ActiveInactiveStatusEnumMap = {
  ActiveInactiveStatus.active: 'active',
  ActiveInactiveStatus.inactive: 'inactive',
};
