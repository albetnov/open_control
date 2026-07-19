import 'package:validasi/validasi.dart';
import 'package:validasi_annotation/validasi_annotation.dart';

part 'connection_form.g.dart';

@ValidateClass()
class ConnectionForm {
  const ConnectionForm({required this.host, this.port = 4455});

  @Validate<String>([
    Regex(
      r'^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
      message: 'Enter a valid IP address or hostname',
    ),
  ])
  final String host;

  @Validate<int>([Between(1, 65535, message: 'Port must be between 1 and 65535')])
  final int port;
}
