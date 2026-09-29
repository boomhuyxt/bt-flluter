import 'package:flutter/material.dart';

enum TempUnit { celsius, fahrenheit, kelvin }

extension TempUnitExt on TempUnit {
  String get symbol {
    switch (this) {
      case TempUnit.celsius:
        return '°C';
      case TempUnit.fahrenheit:
        return '°F';
      case TempUnit.kelvin:
        return 'K';
    }
  }

  String get name {
    switch (this) {
      case TempUnit.celsius:
        return 'Độ C (Celsius)';
      case TempUnit.fahrenheit:
        return 'Độ F (Fahrenheit)';
      case TempUnit.kelvin:
        return 'Độ K (Kelvin)';
    }
  }
}

class TemperatureConverterScreen extends StatefulWidget {
  final bool isEmbedded;
  const TemperatureConverterScreen({super.key, this.isEmbedded = false});

  @override
  State<TemperatureConverterScreen> createState() =>
      _TemperatureConverterScreenState();
}

class _TemperatureConverterScreenState
    extends State<TemperatureConverterScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController(text: '10');
  TempUnit _fromUnit = TempUnit.fahrenheit;
  TempUnit _toUnit = TempUnit.celsius;
  double? _convertedResult;
  String _formulaText = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _calculateConversion();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _calculateConversion() {
    final input = double.tryParse(_controller.text.trim());
    if (input == null) {
      setState(() {
        _convertedResult = null;
        _formulaText = '';
      });
      return;
    }

    double result;
    String formula;

    if (_fromUnit == _toUnit) {
      result = input;
      formula = 'Giữ nguyên giá trị';
    } else if (_fromUnit == TempUnit.fahrenheit && _toUnit == TempUnit.celsius) {
      // F -> C
      result = (input - 32) * 5 / 9;
      formula = '($input°F - 32) × 5/9 = ${result.toStringAsFixed(2)}°C';
    } else if (_fromUnit == TempUnit.celsius && _toUnit == TempUnit.fahrenheit) {
      // C -> F
      result = (input * 9 / 5) + 32;
      formula = '($input°C × 9/5) + 32 = ${result.toStringAsFixed(2)}°F';
    } else if (_fromUnit == TempUnit.celsius && _toUnit == TempUnit.kelvin) {
      // C -> K
      result = input + 273.15;
      formula = '$input°C + 273.15 = ${result.toStringAsFixed(2)} K';
    } else if (_fromUnit == TempUnit.kelvin && _toUnit == TempUnit.celsius) {
      // K -> C
      result = input - 273.15;
      formula = '$input K - 273.15 = ${result.toStringAsFixed(2)}°C';
    } else if (_fromUnit == TempUnit.fahrenheit && _toUnit == TempUnit.kelvin) {
      // F -> K
      result = (input - 32) * 5 / 9 + 273.15;
      formula = '($input°F - 32) × 5/9 + 273.15 = ${result.toStringAsFixed(2)} K';
    } else {
      // K -> F
      result = (input - 273.15) * 9 / 5 + 32;
      formula = '($input K - 273.15) × 9/5 + 32 = ${result.toStringAsFixed(2)}°F';
    }

    setState(() {
      _convertedResult = result;
      _formulaText = formula;
    });
  }

  void _swapUnits() {
    _animController.forward(from: 0.0);
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;

      // Smart reverse: if we had a converted result, put it into controller so reverse conversion is exact
      if (_convertedResult != null) {
        _controller.text = _convertedResult!.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      }
    });
    _calculateConversion();
  }

  Map<String, dynamic> _getSensation(double celsiusVal) {
    if (celsiusVal <= 0) {
      return {'label': 'Đóng băng - Rất buốt', 'emoji': '❄️', 'color': Colors.blue};
    } else if (celsiusVal <= 15) {
      return {'label': 'Lạnh giá - Cần mặc ấm', 'emoji': '🧥', 'color': Colors.cyan};
    } else if (celsiusVal <= 25) {
      return {'label': 'Mát mẻ - Rất dễ chịu', 'emoji': '🌤️', 'color': Colors.teal};
    } else if (celsiusVal <= 35) {
      return {'label': 'Ấm áp - Khá nóng', 'emoji': '☀️', 'color': Colors.amber};
    } else {
      return {'label': 'Nắng nóng gắt - Cực đoan', 'emoji': '🔥', 'color': Colors.deepOrange};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    double? celsiusEquivalent;
    if (_convertedResult != null) {
      final input = double.tryParse(_controller.text.trim()) ?? 0;
      if (_toUnit == TempUnit.celsius) {
        celsiusEquivalent = _convertedResult;
      } else if (_fromUnit == TempUnit.celsius) {
        celsiusEquivalent = input;
      } else if (_toUnit == TempUnit.fahrenheit) {
        celsiusEquivalent = (_convertedResult! - 32) * 5 / 9;
      }
    }

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Chuyển đổi nhiệt độ'),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.thermostat, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quy đổi nhiệt độ chính xác',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hỗ trợ chuyển đổi qua lại giữa °C, °F và Kelvin',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Select Units & Swap Section
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // From unit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Từ đơn vị', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<TempUnit>(
                              isExpanded: true,
                              value: _fromUnit,
                              items: TempUnit.values.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text('${u.symbol} - ${u.name.split(' ')[1]}'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _fromUnit = val);
                                  _calculateConversion();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Swap Button
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.5).animate(_animController),
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _swapUnits,
                        tooltip: 'Đảo ngược chiều chuyển đổi',
                        icon: const Icon(Icons.swap_horiz, size: 26),
                      ),
                    ),

                    // To unit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đến đơn vị', style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<TempUnit>(
                              isExpanded: true,
                              value: _toUnit,
                              items: TempUnit.values.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text('${u.symbol} - ${u.name.split(' ')[1]}'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _toUnit = val);
                                  _calculateConversion();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input Field
            Text(
              'Nhập giá trị (${_fromUnit.symbol}):',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Nhập số nhiệt độ...',
                suffixText: _fromUnit.symbol,
                suffixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.edit),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _calculateConversion();
                  },
                ),
              ),
              onChanged: (_) => _calculateConversion(),
            ),
            const SizedBox(height: 16),

            // Preset Quick Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickChip('0°C (Băng)', '0', TempUnit.celsius),
                _buildQuickChip('37°C (Thân nhiệt)', '37', TempUnit.celsius),
                _buildQuickChip('100°C (Sôi)', '100', TempUnit.celsius),
                _buildQuickChip('10°F (Ví dụ)', '10', TempUnit.fahrenheit),
                _buildQuickChip('77°F (Ấm)', '77', TempUnit.fahrenheit),
              ],
            ),
            const SizedBox(height: 24),

            // Converted Result Display Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                      : [const Color(0xFF4338CA), const Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withAlpha(50),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'KẾT QUẢ QUY ĐỔI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_fromUnit.symbol} ➔ ${_toUnit.symbol}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_convertedResult != null) ...[
                    // Primary sentence notification as requested: "10°F bằng -12.22°C"
                    Text(
                      '${_controller.text} ${_fromUnit.symbol} bằng ${_convertedResult!.toStringAsFixed(2)} ${_toUnit.symbol}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(50),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Công thức: $_formulaText',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Vui lòng nhập số nhiệt độ hợp lệ',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sensation gauge card
            if (celsiusEquivalent != null) ...[
              Builder(
                builder: (context) {
                  final sensation = _getSensation(celsiusEquivalent!);
                  final color = sensation['color'] as MaterialColor;
                  return Card(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            sensation['emoji'] as String,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cảm nhận nhiệt độ:',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sensation['label'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String value, TempUnit unit) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _fromUnit = unit;
          if (_toUnit == unit) {
            _toUnit = unit == TempUnit.celsius ? TempUnit.fahrenheit : TempUnit.celsius;
          }
          _controller.text = value;
        });
        _calculateConversion();
      },
    );
  }
}