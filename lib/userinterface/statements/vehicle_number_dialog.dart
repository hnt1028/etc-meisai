import 'package:etc_meisai/application/usecase/statements/save_vehicle_number_uc.dart';
import 'package:etc_meisai/userinterface/statements/statement_detail_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// OP-3 of SCR-003: asks for a vehicle number. Returns the number the user
/// saved, or null when the dialog was cancelled. The number can be saved once,
/// so the dialog says so.
Future<int?> showVehicleNumberDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (_) => const _VehicleNumberDialog(),
  );
}

class _VehicleNumberDialog extends StatefulWidget {
  const _VehicleNumberDialog();

  @override
  State<_VehicleNumberDialog> createState() => _VehicleNumberDialogState();
}

class _VehicleNumberDialogState extends State<_VehicleNumberDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The number in the field, or null when it is not one to four digits.
  int? get _number {
    final number = int.tryParse(_controller.text);
    if (number == null ||
        number < SaveVehicleNumberUC.smallest ||
        number > SaveVehicleNumberUC.largest) {
      return null;
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(StatementDetailStrings.vehicleNumberDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: const InputDecoration(
              labelText: StatementDetailStrings.vehicleNumberInputLabel,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(
            StatementDetailStrings.vehicleNumberOnceNotice,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(StatementDetailStrings.cancel),
        ),
        FilledButton(
          onPressed: _number == null
              ? null
              : () => Navigator.of(context).pop(_number),
          child: const Text(StatementDetailStrings.save),
        ),
      ],
    );
  }
}
