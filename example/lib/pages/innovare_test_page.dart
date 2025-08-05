import 'package:flutter/material.dart';
import 'package:innovare_data_table/innovare_data_table.dart';
import 'package:innovare_data_table_example/models/active_inactive_status_enum.dart';
import 'package:innovare_data_table_example/models/fetch_town_trucks_response_dto.dart';
import 'package:innovare_data_table_example/models/town_truck_entity.dart';
import 'package:innovare_data_table_example/models/town_trucks_mapper.dart';

class InnovareTestPage extends StatefulWidget {
  const InnovareTestPage({super.key});

  @override
  State<InnovareTestPage> createState() => _InnovareTestPageState();
}

class _InnovareTestPageState extends State<InnovareTestPage> {

  late HttpDataTableSource<TownTruck> _dataSource;
  late DataTableController<TownTruck> _controller;

  @override
  void initState() {
    _setupHttpDataSource();

    super.initState();
  }

  void _setupHttpDataSource() {
    _dataSource = HttpDataTableSource<TownTruck>(
      urlBuilder: (request) {

        var uri = "http://localhost:3001/api/v1/organizations/unic-seguradora/town-trucks?page=${request.page}&offset=${request.pageSize}";

        for (final filter in request.filters) {
          if (filter.field == "statuses" && filter.value != null) {
            uri += "&${filter.field}=${(filter.value as ActiveInactiveStatus).name}";
          } else {
            uri += "&${filter.field}=${filter.value}";
          }
        }

        if (request.searchTerm != null && request.searchTerm!.isNotEmpty) {
          uri += "&name=${Uri.encodeComponent(request.searchTerm!)}";
        }

        return uri;
      },

      headersBuilder: () {
        return {
          'X-App-Token': 'F2C0E700-BEAD-467C-92F9-15A1A5AAD5FB',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2ODU2YjI0NjAxZTNiZDk1NmJlM2Y1OWUiLCJ1c2VybmFtZSI6IkFkbWluaXN0cmFkb3IgVW5pYyIsImVtYWlsIjoiYWRtaW5AdW5pYy5jb20iLCJpYXQiOjE3NTQxNTU4MDUsImV4cCI6MTc1Njc0NzgwNX0.sAfhcCQS4kUtWrS0XAopmlO6470SZAqpcOTToS4J0TBU0V1rsrTEsUd4UXDCajyVJT_sAKR6SyFTAipSQx8ZHQ',
        };
      },

      responseParser: (json) {
        final responseAsMap = json as Map<String, dynamic>;
        final response = FetchTownTrucksResponseDTO.fromJson(responseAsMap['data']);

        return DataTableResult<TownTruck>(
          data: response.data.map((e) => TownTrucksMapper.map(e)).toList(),
          totalCount: response.total,
          page: response.page,
          pageSize: response.offset,
        );
      },

      errorHandler: (error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching data: ${error.toString()}'),
          ),
        );
      },

      enableCache: false,
    );

    _controller = DataTableController<TownTruck>(dataSource: _dataSource);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InnovareDataTableTheme(
        data: InnovareDataTableThemeData(
          density: DataTableDensity.custom,
          customDensity: DensityConfig.comfortable.copyWith(
            rowHeight: 68
          )
        ),
        child: InnovareDataTable<TownTruck>.withDataSource(
          columns: _columns,
          quickActions: _quickActions,
          config: InnovareDataTableConfig.withUnifiedFilters(
            quickFilters: _quickFilters,
            advancedFilters: _advancedFilters,
            fieldGetter: (item, field) {
              switch (field) {
                case 'name':
                  return item.name;
                case 'phone':
                  return item.phones.isNotEmpty
                      ? (item.phones.length == 1
                          ? item.phones.first
                          : '${item.phones.first} + ${item.phones.length - 1}..')
                      : '';
                case 'city':
                  return item.city ?? 'N/A';
                case 'state':
                  return item.state ?? 'N/A';
                case 'status':
                  return item.status.name;
                default:
                  return '';
              }
            }
          ),
          dataSource: _dataSource,
          pageSize: 50,
          controller: _controller,
        )
      )
    );
  }

  List<DataColumnConfig<TownTruck>> get _columns => [
    DataColumnConfig.text(
        field: "name",
        label: "Nome",
        valueGetter: (item) => item.name,
        width: 300
    ),
    DataColumnConfig.text(
      field: "phone",
      label: "Telefones",
      width: 270,
      valueGetter: (item) => item.phones.isNotEmpty
          ? (item.phones.length == 1
          ? item.phones.first
          : '${item.phones.first} + ${item.phones.length - 1}..')
          : '',
      cellBuilder: (item) {
        final phones = item.phones;

        if (phones.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Nenhum telefone cadastrado'),
          );
        }

        if (phones.length > 1) {
          final remainingPhones = phones.length - 1;

          return Row(
            spacing: 5.0,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 200,
                child: Row(
                  spacing: 5.0,
                  children: [
                    Text(
                        phones.first,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        )
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$remainingPhones',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              )
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          width: 200,
          child: Row(
            spacing: 5.0,
            children: [
              Text(
                  phones.first,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  )
              ),
            ],
          ),
        );
      },
    ),
    DataColumnConfig.text(
        field: "city",
        label: "Cidade",
        valueGetter: (item) => item.city ?? 'N/A',
        width: 230
    ),
    DataColumnConfig.text(
      field: "state",
      label: "Estado",
      valueGetter: (item) => item.state ?? 'N/A',
    ),
    DataColumnConfig.status(
        field: "status",
        label: "Status",
        width: 150,
        valueGetter: (item) => item.status.name,
        cellBuilder: (item) => Container(
          width: 120,
          padding: const EdgeInsets.all(8.0),
          child: Row(
            spacing: 5.0,
            children: [
              Text(
                item.status.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
    ),
  ];

  List<QuickActionConfig> get _quickActions => [
    QuickActionConfig.add(
      label: "Adicionar Guincho",
      onPressed: () {}
    ),
  ];

  List<AdvancedFilterConfig<TownTruck>> get _advancedFilters => [
    AdvancedFilterConfig(
      field: 'email',
      label: 'Email',
      type: SimpleFilterType.text,
    ),
  ];

  List<QuickFiltersConfig<TownTruck>> get _quickFilters => [
    QuickFiltersConfig(
        allowMultiple: false,
        groupLabel: "Status",
        filters: [
          QuickFilter(
            id: "status_all",
            label: "Todos",
            field: "statuses",
            value: null,
            color: Colors.grey.shade300,
            icon: Icons.all_inclusive_outlined,
            isDefault: true
          ),
          QuickFilter(
            id: "status_active",
            label: ActiveInactiveStatus.active.name,
            field: "statuses",
            value: ActiveInactiveStatus.active,
            color: Colors.green.shade300,
            icon: Icons.check_circle_outline,
            isDefault: false
          ),
          QuickFilter(
            id: "status_inactive",
            label: ActiveInactiveStatus.inactive.name,
            field: "statuses",
            value: ActiveInactiveStatus.inactive,
            color: Colors.red.shade300,
            icon: Icons.cancel_outlined,
            isDefault: false
          ),
        ]
    )
  ];
}
