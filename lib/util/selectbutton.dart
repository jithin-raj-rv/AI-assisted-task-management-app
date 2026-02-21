import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_list/theme.dart';

class Selectbutton extends ConsumerStatefulWidget {
  final bool initialSelection; // true for text1, false for text2
  final String text1;
  final String text2;
  final Function(bool) onSelectionChanged;

  const Selectbutton({
    super.key,
    this.initialSelection = true,
    required this.text1,
    required this.text2,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<Selectbutton> createState() => _SelectbuttonState();
}

class _SelectbuttonState extends ConsumerState<Selectbutton> {
  late List<bool> _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = [widget.initialSelection, !widget.initialSelection];
  }

  @override
  void didUpdateWidget(Selectbutton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelection != oldWidget.initialSelection) {
      _isSelected = [widget.initialSelection, !widget.initialSelection];
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme= ref.watch(themeProvider);
    return Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [appTheme.background,appTheme.backgroundGradientEnd, appTheme.background],
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  padding: const EdgeInsets.all(2), // gradient border thickness
  child: ToggleButtons(
    isSelected: _isSelected,
    fillColor: Colors.transparent, // important
    selectedColor: appTheme.accentGradientEnd,
    color: appTheme.textGradientStart,
    borderColor: Colors.transparent,
    selectedBorderColor: appTheme.quatenery,
    borderRadius: BorderRadius.circular(8),
    onPressed: (int index) {
      setState(() {
        if (index == 0) {
          _isSelected[0] = true;
          _isSelected[1] = false;
          widget.onSelectionChanged(true);
        } else {
          _isSelected[0] = false;
          _isSelected[1] = true;
          widget.onSelectionChanged(false);
        }
      });
    },
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(widget.text1),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(widget.text2),
      ),
    ],
  ),
);
  }
}