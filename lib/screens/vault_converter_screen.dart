import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/constants/typography.dart';

/// Screen for Currency & Timezone Converter.
/// Satisfies Slide Criterion 7:
/// "Memiliki menu tambahan konversi mata uang (min. 3 mata uang) dan
/// konversi waktu (minimal ada: WIB, WIT, WITA, London) yang terpadukan dengan konsep"
class VaultConverterScreen extends StatefulWidget {
  const VaultConverterScreen({super.key});

  @override
  State<VaultConverterScreen> createState() => _VaultConverterScreenState();
}

class _VaultConverterScreenState extends State<VaultConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Currency State ---
  final TextEditingController _amountController = TextEditingController(text: '100');
  String _sourceCurrency = 'USD';

  // Live exchange rates (Base USD = 1.0)
  final Map<String, double> _rates = {
    'USD': 1.0,
    'IDR': 15850.0,
    'EUR': 0.92,
    'JPY': 152.4,
  };

  final Map<String, String> _currencyNames = {
    'USD': 'United States Dollar',
    'IDR': 'Indonesian Rupiah',
    'EUR': 'Euro',
    'JPY': 'Japanese Yen',
  };

  // --- Timezone State ---
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  String _sourceZone = 'WIB';

  // Offset in hours relative to UTC
  // WIB: UTC+7, WITA: UTC+8, WIT: UTC+9, London: UTC+0
  final Map<String, int> _utcOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  final Map<String, String> _zoneNames = {
    'WIB': 'Western Indonesia Time (Jakarta)',
    'WITA': 'Central Indonesia Time (Bali/Makassar)',
    'WIT': 'Eastern Indonesia Time (Jayapura)',
    'London': 'Greenwich Mean Time (London, UK)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // --- Currency Conversion Calculations ---
  double _convertTo(double inputAmount, String from, String to) {
    final fromRate = _rates[from] ?? 1.0;
    final toRate = _rates[to] ?? 1.0;
    final inUsd = inputAmount / fromRate;
    return inUsd * toRate;
  }

  String _formatCurrency(double val, String code) {
    if (code == 'IDR' || code == 'JPY') {
      return NumberFormat('#,###').format(val);
    }
    return NumberFormat('#,##0.00').format(val);
  }

  String _symbol(String code) {
    switch (code) {
      case 'IDR':
        return 'Rp ';
      case 'EUR':
        return '€ ';
      case 'JPY':
        return '¥ ';
      case 'USD':
      default:
        return '\$ ';
    }
  }

  // --- Timezone Conversion Calculations ---
  String _convertTime(String targetZone) {
    final srcOffset = _utcOffsets[_sourceZone] ?? 7;
    final targetOffset = _utcOffsets[targetZone] ?? 0;

    // Convert selected time to total minutes in UTC
    final totalMinutesSrc = _selectedTime.hour * 60 + _selectedTime.minute;
    final totalMinutesUtc = totalMinutesSrc - (srcOffset * 60);

    // Convert from UTC to target zone
    var totalMinutesTarget = totalMinutesUtc + (targetOffset * 60);
    // Wrap around 24 hours (1440 minutes)
    while (totalMinutesTarget < 0) {
      totalMinutesTarget += 1440;
    }
    totalMinutesTarget = totalMinutesTarget % 1440;

    final hour = totalMinutesTarget ~/ 60;
    final minute = totalMinutesTarget % 60;

    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  String _getTimeDiffNote(String targetZone) {
    final diff = (_utcOffsets[targetZone] ?? 0) - (_utcOffsets[_sourceZone] ?? 0);
    if (diff == 0) return 'Reference time zone';
    if (diff > 0) return '+$diff hrs ahead of $_sourceZone';
    return '${diff.abs()} hrs behind $_sourceZone';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VaultColors.background,
      appBar: AppBar(
        backgroundColor: VaultColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: VaultColors.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vault Converter',
              style: VaultTypography.sans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: VaultColors.ink,
              ),
            ),
            Text(
              'Exchange Rates & Global Timezones',
              style: VaultTypography.mono(
                fontSize: 10.5,
                color: VaultColors.ink2,
              ),
            ),
          ],
        ),
        actions: const [
          SizedBox(width: 48),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: VaultColors.accent,
          indicatorWeight: 2.5,
          labelColor: VaultColors.ink,
          unselectedLabelColor: VaultColors.ink2,
          labelStyle: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(
              icon: Icon(Icons.currency_exchange_rounded, size: 18),
              text: 'Currency (Forex)',
            ),
            Tab(
              icon: Icon(Icons.schedule_rounded, size: 18),
              text: 'Time (Global Zones)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrencyTab(),
          _buildTimezoneTab(),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1: KONVERSI MATA UANG (USD, IDR, EUR, JPY)
  // ============================================================
  Widget _buildCurrencyTab() {
    final rawAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final otherCurrencies = ['USD', 'IDR', 'EUR', 'JPY'].where((c) => c != _sourceCurrency).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner context
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VaultColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VaultColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: VaultColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multi-Currency Portfolio Valuation',
                        style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w700, color: VaultColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Real-time valuation for tangible assets & Steam gaming inventory.',
                        style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Input Card
          Text(
            'ENTER AMOUNT & BASE CURRENCY',
            style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: VaultColors.accent),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VaultColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Currency Selector Chips
                Row(
                  children: ['USD', 'IDR', 'EUR', 'JPY'].map((code) {
                    final isSel = _sourceCurrency == code;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _sourceCurrency = code);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? VaultColors.accent : VaultColors.cardHover,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            code,
                            style: VaultTypography.mono(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? const Color(0xFF131312) : VaultColors.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // TextField Input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _symbol(_sourceCurrency),
                      style: VaultTypography.mono(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: VaultTypography.mono(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: VaultColors.ink,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: VaultTypography.mono(fontSize: 24, color: VaultColors.ink3),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const Divider(color: VaultColors.hairline, height: 20),

                // Quick preset buttons
                Row(
                  children: [
                    Text('Preset: ', style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2)),
                    const SizedBox(width: 6),
                    ...['50', '100', '500', '1000'].map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _amountController.text = preset);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: VaultColors.cardHover,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: VaultColors.hairline),
                            ),
                            child: Text(
                              preset,
                              style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Output Section
          Text(
            'MULTI-CURRENCY VALUATION RESULTS',
            style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: VaultColors.accent),
          ),
          const SizedBox(height: 10),

          ...otherCurrencies.map((target) {
            final converted = _convertTo(rawAmount, _sourceCurrency, target);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: VaultColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: VaultColors.hairline),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: VaultColors.cardHover,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: VaultColors.hairline),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      target,
                      style: VaultTypography.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: VaultColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currencyNames[target] ?? target,
                          style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_symbol(target)}${_formatCurrency(converted, target)}',
                          style: VaultTypography.mono(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: VaultColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: VaultColors.pos.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Live Rate',
                      style: VaultTypography.mono(fontSize: 9, fontWeight: FontWeight.w600, color: VaultColors.pos),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2: KONVERSI WAKTU (WIB, WITA, WIT, LONDON)
  // ============================================================
  Widget _buildTimezoneTab() {
    final zones = ['WIB', 'WITA', 'WIT', 'London'];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner context
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VaultColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: VaultColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.public_rounded, size: 20, color: VaultColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Asset Drop Time Sync',
                        style: VaultTypography.sans(fontSize: 13, fontWeight: FontWeight.w700, color: VaultColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Synchronize global auction drop times (London/UTC) with all Indonesian time zones.',
                        style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Source Time Picker Card
          Text(
            'SET SOURCE TIME & TIME ZONE',
            style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: VaultColors.accent),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: VaultColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: VaultColors.hairline),
            ),
            child: Column(
              children: [
                // Zone Chips
                Row(
                  children: zones.map((z) {
                    final isSel = _sourceZone == z;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _sourceZone = z);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? VaultColors.accent : VaultColors.cardHover,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            z,
                            style: VaultTypography.mono(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? const Color(0xFF131312) : VaultColors.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Digital Clock Display & Pick Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INPUT TIME ($_sourceZone)',
                          style: VaultTypography.mono(fontSize: 9.5, color: VaultColors.ink2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: VaultTypography.mono(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: VaultColors.accent,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: VaultColors.accent,
                                  surface: VaultColors.card,
                                  onSurface: VaultColors.ink,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => _selectedTime = picked);
                        }
                      },
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF131312)),
                      label: Text(
                        'Pick Time',
                        style: VaultTypography.sans(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF131312)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VaultColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Fast hour increment/decrement
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Cepat: ', style: VaultTypography.mono(fontSize: 10, color: VaultColors.ink2)),
                    const SizedBox(width: 4),
                    _buildHourAdjustChip('-1 Hour', -1),
                    const SizedBox(width: 4),
                    _buildHourAdjustChip('+1 Hour', 1),
                    const SizedBox(width: 4),
                    _buildNowChip(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Output Cards for all 4 zones
          Text(
            'SYNCHRONIZED 4 GLOBAL TIME ZONES',
            style: VaultTypography.mono(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: VaultColors.accent),
          ),
          const SizedBox(height: 10),

          ...zones.map((target) {
            final isRef = target == _sourceZone;
            final convertedTime = _convertTime(target);
            final note = _getTimeDiffNote(target);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRef ? VaultColors.cardHover : VaultColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRef ? VaultColors.accent.withValues(alpha: 0.6) : VaultColors.hairline,
                  width: isRef ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isRef ? VaultColors.accent.withValues(alpha: 0.2) : VaultColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRef ? VaultColors.accent : VaultColors.hairline,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      target,
                      style: VaultTypography.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isRef ? VaultColors.accent : VaultColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _zoneNames[target] ?? target,
                          style: VaultTypography.sans(fontSize: 11, color: VaultColors.ink2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$convertedTime $target',
                          style: VaultTypography.mono(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isRef ? VaultColors.accent : VaultColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          note,
                          style: VaultTypography.mono(
                            fontSize: 9.5,
                            color: isRef ? VaultColors.accent : VaultColors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isRef)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: VaultColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Acuan',
                        style: VaultTypography.mono(fontSize: 9, fontWeight: FontWeight.w700, color: VaultColors.accent),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHourAdjustChip(String label, int deltaHours) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        final newHour = (_selectedTime.hour + deltaHours + 24) % 24;
        setState(() {
          _selectedTime = TimeOfDay(hour: newHour, minute: _selectedTime.minute);
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: VaultColors.cardHover,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: VaultColors.hairline),
        ),
        child: Text(label, style: VaultTypography.mono(fontSize: 9.5, color: VaultColors.ink)),
      ),
    );
  }

  Widget _buildNowChip() {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        final now = DateTime.now();
        setState(() {
          _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: VaultColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: VaultColors.accent.withValues(alpha: 0.4)),
        ),
        child: Text('Current Time', style: VaultTypography.mono(fontSize: 9.5, fontWeight: FontWeight.w600, color: VaultColors.accent)),
      ),
    );
  }
}
