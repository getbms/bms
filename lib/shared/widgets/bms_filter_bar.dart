import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bms/core/theme/app_text_styles.dart';

/// A date range field that sizes identically to TextField (uses readOnly TextField internally).
class BmsDateRangeField extends StatelessWidget {
  const BmsDateRangeField({
    super.key,
    required this.start,
    required this.end,
    required this.onPick,
  });

  final DateTime start;
  final DateTime end;
  final void Function(DateTimeRange) onPick;

  static final _fmt = DateFormat('dd MMM yyyy');

  Future<void> _pick(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(start: start, end: end),
    );
    if (picked != null) onPick(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () => _pick(context),
      controller: TextEditingController(
        text: '${_fmt.format(start)}  -  ${_fmt.format(end)}',
      ),
      style: AppTextStyles.bodyMedium,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.date_range_outlined, size: 18),
      ),
    );
  }
}

/// Consistent search field with clear button, uses app theme defaults.
class BmsSearchField extends StatelessWidget {
  const BmsSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search...',
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// Standard filter row: date range on the left, search on the right.
class BmsFilterRow extends StatelessWidget {
  const BmsFilterRow({
    super.key,
    required this.start,
    required this.end,
    required this.onDatePick,
    required this.searchController,
    required this.onSearch,
    this.searchHint = 'Search...',
  });

  final DateTime start;
  final DateTime end;
  final void Function(DateTimeRange) onDatePick;
  final TextEditingController searchController;
  final void Function(String) onSearch;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: BmsDateRangeField(
              start: start,
              end: end,
              onPick: onDatePick,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: BmsSearchField(
              controller: searchController,
              onChanged: onSearch,
              hintText: searchHint,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple date range bar (no search) — used by petty cash, quick sales.
class BmsDateBar extends StatelessWidget {
  const BmsDateBar({
    super.key,
    required this.start,
    required this.end,
    required this.onPick,
  });

  final DateTime start;
  final DateTime end;
  final void Function(DateTimeRange) onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: BmsDateRangeField(start: start, end: end, onPick: onPick),
    );
  }
}
