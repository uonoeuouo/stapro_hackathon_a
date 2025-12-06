class Employee {
  final String id;
  final String name;

  const Employee({
    required this.id,
    required this.name,
  });
}

const mockEmployee = Employee(
  id: 'EMP001',
  name: '山田 太郎',
);

class EmployeeData {
  final String name;
  final DateTime clockInTime;
  final List<int> presetFares; // 事前に登録されている交通費の選択肢

  EmployeeData({
    required this.name,
    required this.clockInTime,
    required this.presetFares,
  });
}

// 画面の親ウィジェットで渡されるデータ
final mockEmployeeData = EmployeeData(
  name: '山田 太郎',
  clockInTime: DateTime(2025, 11, 29, 9, 0, 0), // 9:00に出勤したと仮定
  presetFares: [], // 登録済み交通費 (最初は空)
);
