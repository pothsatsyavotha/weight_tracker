import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weight_entry.dart';
import '../theme/palette.dart';
import 'bouncy.dart';

class AddSheet extends StatefulWidget {
  final WeightEntry? initial;
  const AddSheet({super.key, this.initial});

  @override
  State<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<AddSheet> {
  late DateTime _date;
  late final TextEditingController _ctrl;
  String? _err;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _date = widget.initial?.date ?? DateTime.now();
    _ctrl = TextEditingController(
        text: widget.initial == null
            ? ''
            : widget.initial!.weight.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  void _save() {
    final w = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    if (w == null || w < 20 || w > 400) {
      setState(() => _err = 'Enter a valid weight in kg');
      return;
    }
    Navigator.pop(context, (DateTime(_date.year, _date.month, _date.day), w));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (r) => kMainGradient.createShader(r),
            child: Text(_editing ? 'Edit Weight' : 'Add Weight',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          const SizedBox(height: 16),
          Bouncy(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: kBlue),
                  const SizedBox(width: 12),
                  const Text('Date',
                      style: TextStyle(fontSize: 16, color: kInk)),
                  const Spacer(),
                  Text(DateFormat('d MMMM y').format(_date),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kBlue)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: 'Weight',
              suffixText: 'kg',
              errorText: _err,
              prefixIcon: const Icon(Icons.monitor_weight_outlined,
                  color: kPurple),
              filled: true,
              fillColor: kPurple.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: kPurple, width: 2)),
            ),
            onChanged: (_) {
              if (_err != null) setState(() => _err = null);
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18),
          Bouncy(
            onTap: _save,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: kMainGradient,
                borderRadius: BorderRadius.circular(27),
                boxShadow: [
                  BoxShadow(
                      color: kBlue.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 7)),
                ],
              ),
              child: Text(_editing ? 'Update' : 'Save',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
