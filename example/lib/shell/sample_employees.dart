import 'dart:math';

/// Lightweight model used across the multi-sort, realtime and cache
/// showcases. Holds the minimum needed to demonstrate the table — no
/// freezed/json layer to keep the example readable.
class Employee {
  final int id;
  final String name;
  final String role;
  final String department;
  final int yearsAtCompany;
  final double rating; // 0.0 — 5.0
  final EmployeeStatus status;

  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.yearsAtCompany,
    required this.rating,
    required this.status,
  });

  Employee copyWith({
    String? name,
    String? role,
    String? department,
    int? yearsAtCompany,
    double? rating,
    EmployeeStatus? status,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      department: department ?? this.department,
      yearsAtCompany: yearsAtCompany ?? this.yearsAtCompany,
      rating: rating ?? this.rating,
      status: status ?? this.status,
    );
  }
}

enum EmployeeStatus { active, onLeave, terminated }

extension EmployeeStatusLabel on EmployeeStatus {
  String get label => switch (this) {
        EmployeeStatus.active => 'Active',
        EmployeeStatus.onLeave => 'On leave',
        EmployeeStatus.terminated => 'Terminated',
      };
}

/// Deterministic seed for the showcase — refreshing the page yields the
/// same dataset, so the user can observe sort/filter behaviour without
/// the data shifting under them.
final _rng = Random(42);

List<Employee> sampleEmployees({int count = 40}) {
  const firstNames = [
    'Alice', 'Bruno', 'Carla', 'Diego', 'Elena', 'Felipe', 'Gabriela',
    'Hugo', 'Isabela', 'João', 'Kátia', 'Lucas', 'Marina', 'Nicolas',
    'Olga', 'Pedro', 'Quintina', 'Rafael', 'Sofia', 'Thiago',
  ];
  const lastNames = [
    'Almeida', 'Barbosa', 'Castro', 'Dias', 'Esteves', 'Ferreira',
    'Gomes', 'Henriques', 'Iglesias', 'Justo',
  ];
  const roles = [
    'Engineer',
    'Senior Engineer',
    'Designer',
    'Product Manager',
    'QA Analyst',
    'Tech Lead',
  ];
  const departments = ['Platform', 'Growth', 'Mobile', 'Data', 'Ops'];

  return List<Employee>.generate(count, (i) {
    final fn = firstNames[_rng.nextInt(firstNames.length)];
    final ln = lastNames[_rng.nextInt(lastNames.length)];
    return Employee(
      id: i + 1,
      name: '$fn $ln',
      role: roles[_rng.nextInt(roles.length)],
      department: departments[i % departments.length],
      yearsAtCompany: _rng.nextInt(15),
      rating: (1 + _rng.nextDouble() * 4).toDouble(),
      status: EmployeeStatus.values[_rng.nextInt(EmployeeStatus.values.length)],
    );
  });
}
