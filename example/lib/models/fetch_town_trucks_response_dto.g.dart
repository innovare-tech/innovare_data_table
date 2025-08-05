// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_town_trucks_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FetchTownTrucksResponseDTO _$FetchTownTrucksResponseDTOFromJson(
        Map<String, dynamic> json) =>
    _FetchTownTrucksResponseDTO(
      page: (json['page'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => TownTruckDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$FetchTownTrucksResponseDTOToJson(
        _FetchTownTrucksResponseDTO instance) =>
    <String, dynamic>{
      'page': instance.page,
      'offset': instance.offset,
      'totalPages': instance.totalPages,
      'total': instance.total,
      'data': instance.data,
    };
