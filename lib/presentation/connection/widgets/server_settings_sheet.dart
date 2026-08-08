import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_control/core/theme/app_theme_colors.dart';
import 'package:open_control/data/managers/connection_manager.dart';
import 'package:open_control/data/managers/server_settings_manager.dart';
import 'package:open_control/data/models/connection_form.dart';
import 'package:validasi_ui/validasi_ui.dart';
import 'package:watch_it/watch_it.dart';

/// A password often has to be configured on the server *before* a connection
/// through its OBS relay can succeed, so this lives on the connection screen
/// rather than behind an active session.
class ServerSettingsSheet extends StatefulWidget
    with WatchItStatefulWidgetMixin {
  const ServerSettingsSheet({super.key});

  @override
  State<ServerSettingsSheet> createState() => _ServerSettingsSheetState();
}

class _ServerSettingsSheetState extends State<ServerSettingsSheet> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = createOnce(() => di<ServerSettingsManager>());
    final lastConnected = di<ConnectionManager>().lastConnected;

    callOnce((_) {
      if (lastConnected != null) {
        manager.fetchCommand((
          host: lastConnected.host,
          port: lastConnected.port,
        ));
      }
    });

    final passwordSet = watchValue((ServerSettingsManager m) => m.passwordSet);
    final isFetching = watchValue(
      (ServerSettingsManager m) => m.fetchCommand.isRunning,
    );
    final isSaving = watchValue(
      (ServerSettingsManager m) => m.saveCommand.isRunning,
    );

    registerHandler(
      select: (ServerSettingsManager m) => m.fetchCommand.errors,
      handler: (context, error, _) {
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not check status: ${error.error}')),
        );
      },
    );
    registerHandler(
      select: (ServerSettingsManager m) => m.saveCommand.errors,
      handler: (context, error, _) {
        if (error == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: ${error.error}')),
        );
      },
    );

    final statusText = isFetching
        ? 'Checking…'
        : switch (passwordSet) {
            null => 'Status unknown',
            true => 'Password set',
            false => 'No password set',
          };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ValidasiForm<ConnectionForm>(
        schema: ConnectionFormFields.schema,
        initialValues: ConnectionForm(
          host: lastConnected?.host ?? '192.168.1.1',
          port: lastConnected?.port ?? 8888,
        ),
        builder: (context, submit) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Server Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              Text(
                'Sets the OBS websocket password on the server itself. '
                'The app never stores or sends it.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.mutedColor),
              ),
              const SizedBox(height: 20),
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
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
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
                        onChanged: (text) =>
                            state.onChanged(int.tryParse(text)),
                        style: const TextStyle(
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
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
              Text(
                statusText,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'OBS Password',
                  hintText: 'Leave blank to clear',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : submit((form) {
                          manager.saveCommand((
                            host: form.host,
                            port: form.port,
                            password: _passwordController.text,
                          ));
                          _passwordController.clear();
                        }),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
