import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multipost/core/constants.dart';

class CustomDateTimePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final Function(DateTime) onConfirm;

  const CustomDateTimePicker({
    Key? key,
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
    required this.onConfirm,
  }) : super(key: key);

  @override
  _CustomDateTimePickerState createState() => _CustomDateTimePickerState();
}

class _CustomDateTimePickerState extends State<CustomDateTimePicker> {
  late DateTime _selectedDate;
  late int _hour;
  late int _minute;
  late bool _isPM;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _hour = widget.initialDate.hour % 12 == 0 ? 12 : widget.initialDate.hour % 12;
    _minute = widget.initialDate.minute;
    _isPM = widget.initialDate.hour >= 12;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        1,
      );
      if (_selectedDate.isBefore(widget.minDate)) {
        _selectedDate = widget.minDate;
      }
      if (_selectedDate.isAfter(widget.maxDate)) {
        _selectedDate = widget.maxDate;
      }
    });
  }

  void _selectDate(int day) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  void _updateTime() {
    int adjustedHour = _hour == 12 ? 0 : _hour;
    if (_isPM) {
      adjustedHour += 12;
    }
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        adjustedHour,
        _minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday, 6 = Saturday

    return AlertDialog(
      backgroundColor: AppColors.datePickerBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(datePickerDialogBorderRadius),
      ),
      content: SizedBox(
        width: datePickerWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Month and navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, color: AppColors.datePickerArrow),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: datePickerMonthFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, color: AppColors.datePickerArrow),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: datePickerSpacing),
            // Days of the week
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                  .map((day) => Text(
                        day,
                        style: const TextStyle(
                          color: AppColors.datePickerDayLabel,
                          fontSize: datePickerDayLabelFontSize,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: datePickerSpacing),
            // Calendar grid
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              children: List.generate(startingWeekday, (index) => const SizedBox.shrink())
                ..addAll(List.generate(daysInMonth, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDate.day == day;
                  return GestureDetector(
                    onTap: () => _selectDate(day),
                    child: Container(
                      margin: const EdgeInsets.all(datePickerMargin),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.datePickerDaySelected : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: datePickerDayFontSize,
                          ),
                        ),
                      ),
                    ),
                  );
                })),
            ),
            const SizedBox(height: datePickerSpacing * 2),
            // Time picker
            const Text(
              'Time',
              style: TextStyle(
                color: AppColors.white,
                fontSize: datePickerTimeLabelFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: datePickerSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours
                SizedBox(
                  width: datePickerWheelWidth,
                  height: datePickerWheelHeight,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: datePickerWheelItemExtent,
                    diameterRatio: 1.5,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _hour = index + 1;
                        _updateTime();
                      });
                    },
                    childDelegate: ListWheelChildLoopingListDelegate(
                      children: List.generate(12, (index) {
                        final hour = index + 1;
                        return Center(
                          child: Text(
                            hour.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: datePickerTimeFontSize,
                            ),
                          ),
                        );
                      }),
                    ),
                    controller: FixedExtentScrollController(initialItem: _hour - 1),
                  ),
                ),
                const Text(
                  ':',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: datePickerTimeFontSize,
                  ),
                ),
                // Minutes
                SizedBox(
                  width: datePickerWheelWidth,
                  height: datePickerWheelHeight,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: datePickerWheelItemExtent,
                    diameterRatio: 1.5,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _minute = index;
                        _updateTime();
                      });
                    },
                    childDelegate: ListWheelChildLoopingListDelegate(
                      children: List.generate(60, (index) {
                        return Center(
                          child: Text(
                            index.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: datePickerTimeFontSize,
                            ),
                          ),
                        );
                      }),
                    ),
                    controller: FixedExtentScrollController(initialItem: _minute),
                  ),
                ),
                const SizedBox(width: datePickerSpacing),
                // AM/PM
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPM = false;
                          _updateTime();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: datePickerAmPmVerticalPadding,
                          horizontal: datePickerAmPmHorizontalPadding,
                        ),
                        color: !_isPM ? AppColors.datePickerAmPmSelected : Colors.transparent,
                        child: const Text(
                          'AM',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: datePickerAmPmFontSize,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: datePickerSpacing),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isPM = true;
                          _updateTime();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: datePickerAmPmVerticalPadding,
                          horizontal: datePickerAmPmHorizontalPadding,
                        ),
                        color: _isPM ? AppColors.datePickerAmPmSelected : Colors.transparent,
                        child: const Text(
                          'PM',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: datePickerAmPmFontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: datePickerSpacing * 2),
            // Confirm button
            ElevatedButton(
              onPressed: () {
                widget.onConfirm(_selectedDate);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.datePickerArrow,
                padding: const EdgeInsets.symmetric(
                  horizontal: datePickerButtonHorizontalPadding,
                  vertical: datePickerButtonVerticalPadding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(datePickerButtonBorderRadius),
                ),
              ),
              child: const Text(
                'Запланировать',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: datePickerButtonFontSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}