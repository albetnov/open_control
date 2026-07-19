import 'package:flutter/material.dart';
import 'package:open_control/data/models/connection_form.dart';
import 'package:open_control/data/models/obs_connection.dart';
import 'package:validasi_ui/validasi_ui.dart';

class NewConnectionForm extends StatelessWidget {
  const NewConnectionForm({
    required this.defaultHost,
    required this.isConnecting,
    required this.onConnect,
    super.key,
  });

  final String defaultHost;
  final bool isConnecting;
  final void Function(ObsConnection connection) onConnect;

  @override
  Widget build(BuildContext context) {
    return ValidasiForm<ConnectionForm>(
      schema: ConnectionFormFields.schema,
      initialValues: ConnectionForm(host: defaultHost),
      builder: (context, submit) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ValidasiTextField<ConnectionForm, String>(
                    field: ConnectionFormFields.host,
                    builder: (context, state, controller) => TextField(
                      controller: controller,
                      onChanged: state.onChanged,
                      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                      decoration: InputDecoration(
                        labelText: 'Host',
                        hintText: '192.168.1.42',
                        errorText: state.errorText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValidasiTextField<ConnectionForm, int>(
                    field: ConnectionFormFields.port,
                    builder: (context, state, controller) => TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      onChanged: (text) => state.onChanged(int.tryParse(text)),
                      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                      decoration: InputDecoration(
                        labelText: 'Port',
                        errorText: state.errorText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isConnecting
                    ? null
                    : submit((form) => onConnect(ObsConnection(host: form.host, port: form.port))),
                child: isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Connect'),
              ),
            ),
          ],
        );
      },
    );
  }
}
