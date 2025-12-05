import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeparturePage extends StatefulWidget {
  final String userName;
  final String cardId;
  final DateTime clockInTime;
  final DateTime clockOutTime;
  final VoidCallback onConfirm;

  const DeparturePage({
    super.key,
    required this.userName,
    required this.cardId,
    required this.clockInTime,
    required this.clockOutTime,
    required this.onConfirm,
  });

  @override
  State<DeparturePage> createState() => _DeparturePageState();
}

class _DeparturePageState extends State<DeparturePage> {
  int? _selectedFareIndex;
  int? _selectedKoma;
  int _manualFare = 0;
  final TextEditingController _fareController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Mock Presets
  final List<int> _presetFares = [500, 1000];

  @override
  void initState() {
    super.initState();
    _fareController.addListener(() {
      setState(() {
        _manualFare = int.tryParse(_fareController.text) ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  int get _finalFare {
    if (_selectedFareIndex == 0) return 0;
    if (_selectedFareIndex == 1) return _manualFare;
    if (_selectedFareIndex != null && _selectedFareIndex! >= 2) {
      return _presetFares[_selectedFareIndex! - 2];
    }
    return 0;
  }

  void _submit() {
    if (_selectedFareIndex == 1 && !_formKey.currentState!.validate()) {
      return;
    }

    // TODO: Implement actual API call here
    print('退勤時刻: ${widget.clockOutTime}');
    print('登録交通費: $_finalFare円');
    print('登録コマ数: $_selectedKomaコマ');

    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('HH:mm:ss');

    final List<String> fareOptions = [
      'なし',
      '手入力',
      ..._presetFares.map((fare) => '${fare}円'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('退勤処理'),
        automaticallyImplyLeading: false,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Left Side: Info
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30.0),
              color: Colors.blueGrey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'お疲れ様でした',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('社員名:', widget.userName),
                  _buildInfoRow('日付:', dateFormat.format(widget.clockOutTime)),
                  _buildInfoRow('出勤時刻:', timeFormat.format(widget.clockInTime)),
                  _buildInfoRow('退勤時刻:', timeFormat.format(widget.clockOutTime)),
                ],
              ),
            ),
          ),

          // Right Side: Form
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(30.0),
              color: Colors.white,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      '交通費精算',
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    ...List.generate(fareOptions.length, (index) {
                      return RadioListTile<int>(
                        title: Text(fareOptions[index]),
                        value: index,
                        groupValue: _selectedFareIndex,
                        onChanged: (int? value) {
                          setState(() {
                            _selectedFareIndex = value;
                          });
                        },
                      );
                    }),

                    if (_selectedFareIndex == 1)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 15.0, right: 15.0, top: 10),
                        child: TextFormField(
                          controller: _fareController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '交通費 (円)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_selectedFareIndex == 1 &&
                                (value == null ||
                                    value.isEmpty ||
                                    int.tryParse(value) == null)) {
                              return '交通費を入力してください。';
                            }
                            return null;
                          },
                        ),
                      ),

                    const SizedBox(height: 30),

                    if (_selectedFareIndex != null) ...[
                      const Text(
                        '本日のコマ数',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10.0,
                        children: List.generate(5, (index) {
                          final koma = index + 1;
                          return ChoiceChip(
                            label: Text('$komaコマ'),
                            selected: _selectedKoma == koma,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedKoma = selected ? koma : null;
                              });
                            },
                          );
                        }),
                      ),
                    ],

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed:
                            (_selectedFareIndex != null && _selectedKoma != null)
                                ? _submit
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                        child: Text(
                          _selectedFareIndex == null
                              ? '交通費を選択してください'
                              : _selectedKoma == null
                                  ? 'コマ数を選択してください'
                                  : '退勤登録を完了する',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
