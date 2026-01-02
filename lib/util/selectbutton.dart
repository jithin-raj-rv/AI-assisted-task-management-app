import 'package:flutter/material.dart';

class Selectbutton extends StatefulWidget {
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
  State<Selectbutton> createState() => _SelectbuttonState();
}

class _SelectbuttonState extends State<Selectbutton> {
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
    return ToggleButtons(
      isSelected: _isSelected,
      selectedColor: Colors.amber,
      selectedBorderColor: Colors.amber,
      fillColor: Colors.amber.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8.0),
      onPressed: (int index) {
        setState(() {
          if (index == 0) {
            if (!_isSelected[0]) {
              _isSelected[0] = true;
              _isSelected[1] = false;
              widget.onSelectionChanged(true);
            }
          } else {
            if (!_isSelected[1]) {
              _isSelected[0] = false;
              _isSelected[1] = true;
              widget.onSelectionChanged(false);
            }
          }
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(widget.text1, style: const TextStyle(color: Colors.white)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(widget.text2, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}