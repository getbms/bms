import 'package:bms/core/theme/app_colors.dart';
import 'package:bms/core/theme/app_text_styles.dart';
import 'package:bms/core/utils/currency_utils.dart';
import 'package:bms/core/utils/date_utils.dart';
import 'package:bms/data/database/app_database.dart';
import 'package:bms/providers/cheques_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChequeScreen extends ConsumerStatefulWidget {
  const ChequeScreen({super.key});

  @override
  ConsumerState<ChequeScreen> createState() => _ChequeScreenState();
}

class _ChequeScreenState extends ConsumerState<ChequeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _monthDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _prevMonth() => setState(() {
        _monthDate = DateTime(_monthDate.year, _monthDate.month - 1);
      });

  void _nextMonth() => setState(() {
        _monthDate = DateTime(_monthDate.year, _monthDate.month + 1);
      });

  void _openAddCheque() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddChequeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cheques'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'By Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UpcomingTab(),
          _ByMonthTab(monthDate: _monthDate, onPrev: _prevMonth, onNext: _nextMonth),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCheque,
        tooltip: 'Add Cheque',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _UpcomingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(chequesUpcomingProvider);
    return upcomingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cheques) {
        if (cheques.isEmpty) {
          return const Center(child: Text('No cheques due in the next 7 days.', style: AppTextStyles.bodySmall));
        }
        return ListView.builder(
          itemCount: cheques.length,
          itemBuilder: (_, i) => _ChequeRow(cheque: cheques[i]),
        );
      },
    );
  }
}

class _ByMonthTab extends ConsumerWidget {
  const _ByMonthTab({required this.monthDate, required this.onPrev, required this.onNext});
  final DateTime monthDate;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _monthName(int month) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][month];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chequesAsync = ref.watch(chequesMonthStreamProvider((monthDate.year, monthDate.month)));

    return Column(
      children: [
        // Month nav header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
              Text(
                '${_monthName(monthDate.month)} ${monthDate.year}',
                style: AppTextStyles.titleMedium,
              ),
              IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        // Weekday header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _weekDays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: AppTextStyles.bodySmall
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        Expanded(
          child: chequesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (cheques) {
              // Group cheques by day-of-month
              final byDay = <int, List<Cheque>>{};
              for (final c in cheques) {
                byDay.putIfAbsent(c.dueDate.day, () => []).add(c);
              }
              return _CalendarGrid(
                monthDate: monthDate,
                byDay: byDay,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.monthDate, required this.byDay});
  final DateTime monthDate;
  final Map<int, List<Cheque>> byDay;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(monthDate.year, monthDate.month);
    // weekday: Mon=1 … Sun=7. We want Mon at index 0.
    final startOffset = firstDay.weekday - 1;
    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == monthDate.year && today.month == monthDate.month;

    // Total cells: pad start, then days
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: List.generate(rows, (row) {
          return Expanded(
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNumber = cellIndex - startOffset + 1;
                final isValid = dayNumber >= 1 && dayNumber <= daysInMonth;
                final isToday = isCurrentMonth && isValid && dayNumber == today.day;
                final dayCheques = isValid ? (byDay[dayNumber] ?? []) : <Cheque>[];

                return Expanded(
                  child: GestureDetector(
                    onTap: dayCheques.isEmpty
                        ? null
                        : () => _showDaySheet(context, dayNumber, dayCheques),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary.withAlpha(20)
                            : dayCheques.isNotEmpty
                                ? AppColors.warningLight
                                : null,
                        border: isToday
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : Border.all(
                                color: dayCheques.isNotEmpty
                                    ? AppColors.warning.withAlpha(80)
                                    : Colors.grey.withAlpha(30),
                                width: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isValid
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNumber',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isToday ? AppColors.primary : null,
                                    fontSize: 12,
                                  ),
                                ),
                                if (dayCheques.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  _ChequeDots(cheques: dayCheques),
                                ],
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  void _showDaySheet(BuildContext context, int day, List<Cheque> cheques) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DayChequeSheet(day: day, monthDate: monthDate, cheques: cheques),
    );
  }
}

class _ChequeDots extends StatelessWidget {
  const _ChequeDots({required this.cheques});
  final List<Cheque> cheques;

  @override
  Widget build(BuildContext context) {
    final received = cheques.where((c) => c.type == 'received').length;
    final issued = cheques.where((c) => c.type == 'issued').length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (received > 0)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
        if (issued > 0)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _DayChequeSheet extends ConsumerWidget {
  const _DayChequeSheet({
    required this.day,
    required this.monthDate,
    required this.cheques,
  });
  final int day;
  final DateTime monthDate;
  final List<Cheque> cheques;

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              '$day ${_monthNames[monthDate.month]} ${monthDate.year}',
              style: AppTextStyles.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: cheques.length,
              itemBuilder: (_, i) => _ChequeRow(cheque: cheques[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChequeRow extends ConsumerWidget {
  const _ChequeRow({required this.cheque});
  final Cheque cheque;

  Color _statusColor(String status) => switch (status) {
        'deposited' => AppColors.chequeDeposited,
        'cleared' => AppColors.chequeCleared,
        'bounced' => AppColors.chequeBounced,
        _ => AppColors.chequePending,
      };

  Color _statusBg(String status) => switch (status) {
        'deposited' => const Color(0xFFE3F2FD),
        'cleared' => AppColors.successLight,
        'bounced' => AppColors.errorLight,
        _ => AppColors.warningLight,
      };

  void _showStatusMenu(BuildContext context, WidgetRef ref) {
    final actions = ref.read(chequeActionsProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Mark as Deposited'),
              leading: const Icon(Icons.account_balance),
              enabled: cheque.status == 'pending',
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  await actions.updateStatus(cheque.id, 'deposited');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
            ListTile(
              title: const Text('Mark as Cleared'),
              leading: const Icon(Icons.check_circle_outline),
              enabled: cheque.status != 'cleared',
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  await actions.updateStatus(cheque.id, 'cleared');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
            ListTile(
              title: const Text('Mark as Bounced'),
              leading: const Icon(Icons.cancel_outlined),
              enabled: cheque.status != 'bounced',
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  await actions.updateStatus(cheque.id, 'bounced');
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(cheque.partyName, style: AppTextStyles.labelLarge),
      subtitle: Text(
        [
          if (cheque.chequeNo != null) '#${cheque.chequeNo}',
          if (cheque.bank != null) cheque.bank!,
          'Due: ${BmsDateUtils.formatDate(cheque.dueDate)}',
        ].join(' · '),
        style: AppTextStyles.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(CurrencyUtils.format(cheque.amount), style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusBg(cheque.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              cheque.status.toUpperCase(),
              style: AppTextStyles.bodySmall.copyWith(
                color: _statusColor(cheque.status),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      leading: Icon(
        cheque.type == 'received' ? Icons.arrow_downward : Icons.arrow_upward,
        color: cheque.type == 'received' ? AppColors.success : AppColors.error,
      ),
      onLongPress: () => _showStatusMenu(context, ref),
      onTap: () => _showStatusMenu(context, ref),
    );
  }
}

class _AddChequeSheet extends ConsumerStatefulWidget {
  const _AddChequeSheet();

  @override
  ConsumerState<_AddChequeSheet> createState() => _AddChequeSheetState();
}

class _AddChequeSheetState extends ConsumerState<_AddChequeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _partyName = TextEditingController();
  final _partyId = TextEditingController();
  final _amount = TextEditingController();
  final _chequeNo = TextEditingController();
  final _bank = TextEditingController();
  final _notes = TextEditingController();

  String _type = 'received';
  String _partyType = 'customer';
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _partyName.dispose();
    _partyId.dispose();
    _amount.dispose();
    _chequeNo.dispose();
    _bank.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(chequeActionsProvider).addCheque(
            type: _type,
            partyId: _partyId.text.trim().isEmpty ? _partyName.text.trim() : _partyId.text.trim(),
            partyType: _partyType,
            partyName: _partyName.text.trim(),
            amount: double.parse(_amount.text),
            dueDate: _dueDate!,
            chequeNo: _chequeNo.text.trim().isEmpty ? null : _chequeNo.text.trim(),
            bank: _bank.text.trim().isEmpty ? null : _bank.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cheque recorded.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Record Cheque', style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'received', child: Text('Received')),
                        DropdownMenuItem(value: 'issued', child: Text('Issued')),
                      ],
                      onChanged: (v) => setState(() => _type = v ?? 'received'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _partyType,
                      decoration: const InputDecoration(labelText: 'Party Type'),
                      items: const [
                        DropdownMenuItem(value: 'customer', child: Text('Customer')),
                        DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _partyType = v ?? 'customer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _partyName,
                decoration: const InputDecoration(labelText: 'Party Name *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(labelText: 'Amount *', prefixText: 'Rs. '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Due Date *'),
                  child: Text(
                    _dueDate != null ? BmsDateUtils.formatDate(_dueDate!) : 'Tap to select',
                    style: _dueDate != null ? AppTextStyles.bodyMedium : AppTextStyles.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _chequeNo,
                      decoration: const InputDecoration(labelText: 'Cheque No.'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _bank,
                      decoration: const InputDecoration(labelText: 'Bank'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Record Cheque'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
