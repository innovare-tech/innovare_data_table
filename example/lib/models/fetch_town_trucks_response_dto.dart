import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:innovare_data_table_example/models/town_truck_dto.dart';

part 'fetch_town_trucks_response_dto.freezed.dart';
part 'fetch_town_trucks_response_dto.g.dart';

@unfreezed
sealed class FetchTownTrucksResponseDTO with _$FetchTownTrucksResponseDTO {
  factory FetchTownTrucksResponseDTO({
    required int page,
    required int offset,
    required int totalPages,
    required int total,
    @Default([]) List<TownTruckDTO> data
  }) = _FetchTownTrucksResponseDTO;

  factory FetchTownTrucksResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$FetchTownTrucksResponseDTOFromJson(json);
}