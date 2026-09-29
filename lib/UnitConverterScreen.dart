import 'package:flutter/material.dart';

class MeasureUnit {
  final String id;
  final String name;
  final String symbol;
  final double toBaseFactor; // Factor to multiply to get base unit

  const MeasureUnit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.toBaseFactor,
  });
}

enum UnitCategory { length, weight, volume, area }

class UnitConverterScreen extends StatefulWidget {
  final bool isEmbedded;
  const UnitConverterScreen({super.key, this.isEmbedded = false});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController(text: '10');
  UnitCategory _currentCategory = UnitCategory.length;
  late MeasureUnit _fromUnit;
  late MeasureUnit _toUnit;
  double? _convertedResult;
  late AnimationController _animController;
  int _decimalPlaces = 4;

  static const Map<UnitCategory, List<MeasureUnit>> _unitsByCategory = {
    UnitCategory.length: [
      MeasureUnit(id: 'mm', name: 'Millimét', symbol: 'mm', toBaseFactor: 0.001),
      MeasureUnit(id: 'cm', name: 'Centimét', symbol: 'cm', toBaseFactor: 0.01),
      MeasureUnit(id: 'dm', name: 'Đêximét', symbol: 'dm', toBaseFactor: 0.1),
      MeasureUnit(id: 'm', name: 'Mét', symbol: 'm', toBaseFactor: 1.0),
      MeasureUnit(id: 'km', name: 'Kilômét', symbol: 'km', toBaseFactor: 1000.0),
      MeasureUnit(id: 'in', name: 'Inch', symbol: 'in', toBaseFactor: 0.0254),
      MeasureUnit(id: 'ft', name: 'Feet', symbol: 'ft', toBaseFactor: 0.3048),
      MeasureUnit(id: 'yd', name: 'Yard', symbol: 'yd', toBaseFactor: 0.9144),
      MeasureUnit(id: 'mi', name: 'Dặm (Mile)', symbol: 'mi', toBaseFactor: 1609.344),
      MeasureUnit(id: 'nmi', name: 'Hải lý', symbol: 'NM', toBaseFactor: 1852.0),
    ],
    UnitCategory.weight: [
      MeasureUnit(id: 'mg', name: 'Miligram', symbol: 'mg', toBaseFactor: 0.000001),
      MeasureUnit(id: 'g', name: 'Gram', symbol: 'g', toBaseFactor: 0.001),
      MeasureUnit(id: 'lang', name: 'Lạng (100g)', symbol: 'lạng', toBaseFactor: 0.1),
      MeasureUnit(id: 'kg', name: 'Kilogram', symbol: 'kg', toBaseFactor: 1.0),
      MeasureUnit(id: 'yen', name: 'Yến (10kg)', symbol: 'yến', toBaseFactor: 10.0),
      MeasureUnit(id: 'ta', name: 'Tạ (100kg)', symbol: 'tạ', toBaseFactor: 100.0),
      MeasureUnit(id: 'tan', name: 'Tấn (1000kg)', symbol: 'tấn', toBaseFactor: 1000.0),
      MeasureUnit(id: 'oz', name: 'Ounce', symbol: 'oz', toBaseFactor: 0.028349523125),
      MeasureUnit(id: 'lb', name: 'Pound (lbs)', symbol: 'lb', toBaseFactor: 0.45359237),
    ],
    UnitCategory.volume: [
      MeasureUnit(id: 'ml', name: 'Mililít', symbol: 'mL', toBaseFactor: 0.001),
      MeasureUnit(id: 'cl', name: 'Centilít', symbol: 'cL', toBaseFactor: 0.01),
      MeasureUnit(id: 'l', name: 'Lít', symbol: 'L', toBaseFactor: 1.0),
      MeasureUnit(id: 'm3', name: 'Mét khối', symbol: 'm³', toBaseFactor: 1000.0),
      MeasureUnit(id: 'floz', name: 'Fluid Ounce (fl oz)', symbol: 'fl oz', toBaseFactor: 0.02957353),
      MeasureUnit(id: 'cup', name: 'Cốc (Cup)', symbol: 'cup', toBaseFactor: 0.24),
      MeasureUnit(id: 'gal', name: 'Gallon (Mỹ)', symbol: 'gal', toBaseFactor: 3.785411784),
    ],
    UnitCategory.area: [
      MeasureUnit(id: 'mm2', name: 'Millimét vuông', symbol: 'mm²', toBaseFactor: 0.000001),
      MeasureUnit(id: 'cm2', name: 'Centimét vuông', symbol: 'cm²', toBaseFactor: 0.0001),
      MeasureUnit(id: 'm2', name: 'Mét vuông', symbol: 'm²', toBaseFactor: 1.0),
      MeasureUnit(id: 'ha', name: 'Hécta', symbol: 'ha', toBaseFactor: 10000.0),
      MeasureUnit(id: 'km2', name: 'Kilômét vuông', symbol: 'km²', toBaseFactor: 1000000.0),
      MeasureUnit(id: 'ft2', name: 'Feet vuông', symbol: 'ft²', toBaseFactor: 0.09290304),
      MeasureUnit(id: 'acre', name: 'Mẫu Anh (Acre)', symbol: 'acre', toBaseFactor: 4046.8564224),
    ],
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fromUnit = _unitsByCategory[UnitCategory.length]![3]; // Mét (m)
    _toUnit = _unitsByCategory[UnitCategory.length]![6]; // Feet (ft)
    _calculateConversion();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onCategoryChanged(UnitCategory category) {
    setState(() {
      _currentCategory = category;
      final units = _unitsByCategory[category]!;
      _fromUnit = units.firstWhere((u) => u.toBaseFactor == 1.0, orElse: () => units[0]);
      _toUnit = units.firstWhere((u) => u.id != _fromUnit.id, orElse: () => units[0]);
    });
    _calculateConversion();
  }

  void _calculateConversion() {
    final input = double.tryParse(_controller.text.trim());
    if (input == null) {
      setState(() => _convertedResult = null);
      return;
    }

    // Exact conversion: value * (fromFactor / toFactor)
    final inBase = input * _fromUnit.toBaseFactor;
    final result = inBase / _toUnit.toBaseFactor;

    setState(() {
      _convertedResult = result;
    });
  }

  void _swapUnits() {
    _animController.forward(from: 0.0);
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;

      // Smart reverse conversion: set the input to the exact converted value
      // so 10 m = 32.81 ft -> swapping will compute 32.81 ft = 10 m!
      if (_convertedResult != null) {
        _controller.text = _formatNumber(_convertedResult!);
      }
    });
    _calculateConversion();
  }

  String _formatNumber(double val) {
    if (val == 0) return '0';
    if (val.abs() >= 1000000 || (val.abs() < 0.00001 && val != 0)) {
      return val.toStringAsExponential(_decimalPlaces);
    }
    // Round to selected decimal places and remove trailing zeroes
    String fixed = val.toStringAsFixed(_decimalPlaces);
    if (fixed.contains('.')) {
      fixed = fixed.replaceAll(RegExp(r'0+$'), '');
      if (fixed.endsWith('.')) {
        fixed = fixed.substring(0, fixed.length - 1);
      }
    }
    return fixed;
  }

  // Find the best-fit unit (đơn vị tối ưu / phù hợp nhất)
  Map<String, dynamic>? _getBestFitUnit() {
    final input = double.tryParse(_controller.text.trim());
    if (input == null || input == 0) return null;

    final inBase = (input * _fromUnit.toBaseFactor).abs();
    final units = _unitsByCategory[_currentCategory]!;

    MeasureUnit? bestUnit;
    double bestDiff = double.infinity;

    for (final u in units) {
      final val = inBase / u.toBaseFactor;
      // Ideally between 1 and 1000
      if (val >= 1.0 && val < 1000.0) {
        final diff = (val - 10.0).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          bestUnit = u;
        }
      }
    }

    bestUnit ??= units.firstWhere((u) => u.toBaseFactor == 1.0, orElse: () => units[0]);

    final convertedVal = (input * _fromUnit.toBaseFactor) / bestUnit.toBaseFactor;
    return {
      'unit': bestUnit,
      'value': convertedVal,
      'formatted': _formatNumber(convertedVal),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final availableUnits = _unitsByCategory[_currentCategory]!;
    final unitRate = (1.0 * _fromUnit.toBaseFactor) / _toUnit.toBaseFactor;
    final bestFit = _getBestFitUnit();

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Chuyển đổi đơn vị đo'),
        actions: [
          // Decimal places selector
          PopupMenuButton<int>(
            tooltip: 'Độ chính xác chữ số thập phân',
            icon: const Icon(Icons.tune),
            onSelected: (places) {
              setState(() {
                _decimalPlaces = places;
              });
              _calculateConversion();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 2, child: Text('2 chữ số lẻ (0.01)')),
              const PopupMenuItem(value: 4, child: Text('4 chữ số lẻ (Chuẩn)')),
              const PopupMenuItem(value: 6, child: Text('6 chữ số lẻ (Chính xác cao)')),
              const PopupMenuItem(value: 8, child: Text('8 chữ số lẻ (Khoa học)')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Segmented Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildCategoryTab('Chiều dài', Icons.straighten, UnitCategory.length),
                  _buildCategoryTab('Khối lượng', Icons.fitness_center, UnitCategory.weight),
                  _buildCategoryTab('Dung tích', Icons.water_drop, UnitCategory.volume),
                  _buildCategoryTab('Diện tích', Icons.crop_square, UnitCategory.area),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Units & Swap Section
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // From unit dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Từ đơn vị',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<MeasureUnit>(
                              isExpanded: true,
                              value: _fromUnit,
                              items: availableUnits.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text(
                                    '${u.name} (${u.symbol})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_animController),
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: _swapUnits,
                          tooltip: 'Đảo ngược chiều chuyển đổi (Kèm kết quả)',
                          icon: const Icon(Icons.swap_horiz, size: 26),
                        ),
                      ),
                    ),

                    // To unit dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đến đơn vị',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<MeasureUnit>(
                              isExpanded: true,
                              value: _toUnit,
                              items: availableUnits.map((u) {
                                return DropdownMenuItem(
                                  value: u,
                                  child: Text(
                                    '${u.name} (${u.symbol})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
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

            // Value Input Field
            Text(
              'Nhập số lượng (${_fromUnit.name} - ${_fromUnit.symbol}):',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Nhập giá trị cần đổi...',
                suffixText: _fromUnit.symbol,
                suffixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.edit_note),
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
            const SizedBox(height: 14),

            // Quick preset chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickValChip('1'),
                _buildQuickValChip('5'),
                _buildQuickValChip('10'),
                _buildQuickValChip('50'),
                _buildQuickValChip('100'),
                _buildQuickValChip('1000'),
              ],
            ),
            const SizedBox(height: 20),

            // Best-fit unit banner (Gợi ý đơn vị chuẩn / phù hợp nhất)
            if (bestFit != null && (bestFit['unit'] as MeasureUnit).id != _toUnit.id)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _toUnit = bestFit['unit'] as MeasureUnit;
                  });
                  _calculateConversion();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.amber.withAlpha(100) : Colors.amber,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Đơn vị phù hợp nhất: ${_controller.text} ${_fromUnit.symbol} = ${bestFit['formatted']} ${(bestFit['unit'] as MeasureUnit).symbol}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.amber[200] : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 18, color: Colors.amber),
                    ],
                  ),
                ),
              ),

            // Main Result Display Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F3854), const Color(0xFF065F46)]
                      : [const Color(0xFF0D9488), const Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withAlpha(50),
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
                        'KẾT QUẢ ĐƠN VỊ ĐO CHUẨN XÁC',
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_convertedResult != null) ...[
                    // Clear notification statement: "10 m bằng 32.81 ft"
                    Text(
                      '${_controller.text} ${_fromUnit.symbol} bằng ${_formatNumber(_convertedResult!)} ${_toUnit.symbol}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_controller.text} ${_fromUnit.name} = ${_formatNumber(_convertedResult!)} ${_toUnit.name}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tỷ lệ: 1 ${_fromUnit.symbol} = ${_formatNumber(unitRate)} ${_toUnit.symbol}   (hoặc 1 ${_toUnit.symbol} = ${_formatNumber(1.0 / unitRate)} ${_fromUnit.symbol})',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Vui lòng nhập giá trị hợp lệ để quy đổi',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // All Units Conversion Table Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bảng đổi sang tất cả các đơn vị:',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Chạm để chọn',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // All Units Conversion Cards
            ...availableUnits.map((u) {
              final isCurrentTo = u.id == _toUnit.id;
              final isCurrentFrom = u.id == _fromUnit.id;
              final input = double.tryParse(_controller.text.trim()) ?? 0;
              final converted = (input * _fromUnit.toBaseFactor) / u.toBaseFactor;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCurrentTo
                        ? theme.colorScheme.primary
                        : (isCurrentFrom ? Colors.orange : Colors.transparent),
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: isCurrentTo
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    foregroundColor: isCurrentTo ? Colors.white : (isDark ? Colors.white : Colors.black87),
                    child: Text(
                      u.symbol.substring(0, u.symbol.length > 2 ? 2 : u.symbol.length),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    u.name,
                    style: TextStyle(
                      fontWeight: isCurrentTo ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '1 ${_fromUnit.symbol} = ${_formatNumber((1.0 * _fromUnit.toBaseFactor) / u.toBaseFactor)} ${u.symbol}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_formatNumber(converted)} ${u.symbol}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCurrentTo ? theme.colorScheme.primary : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isCurrentTo)
                        const Icon(Icons.check_circle, color: Colors.green, size: 18)
                      else
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _toUnit = u;
                    });
                    _calculateConversion();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String title, IconData icon, UnitCategory category) {
    final isSelected = _currentCategory == category;
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => _onCategoryChanged(category),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickValChip(String val) {
    return ActionChip(
      label: Text(val),
      onPressed: () {
        _controller.text = val;
        _calculateConversion();
      },
    );
  }
}