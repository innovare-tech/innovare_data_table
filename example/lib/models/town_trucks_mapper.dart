import 'package:innovare_data_table_example/models/town_truck_dto.dart';
import 'package:innovare_data_table_example/models/town_truck_entity.dart';

class TownTrucksMapper {
  static TownTruck map(TownTruckDTO input) {
    return TownTruck(
      id: input.id,
      organizationId: input.organizationId,
      name: input.name,
      document: input.document,
      phones: input.phones,
      email: input.email,
      city: input.city,
      state: input.state,
      zipCode: input.zipCode,
      externalId: input.externalId,
      status: input.status,
    );
  }

}