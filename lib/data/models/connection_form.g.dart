// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_form.dart';

sealed class ConnectionFormFields<V> extends ValidasiKey<ConnectionForm>
    implements ValidasiField<ConnectionForm, V> {
  const ConnectionFormFields._();

  static const ValidasiSchema<ConnectionForm> schema = _ConnectionFormSchema();

  static const ConnectionFormFields<String> host = ConnectionFormHostField();

  static const ConnectionFormFields<int> port = ConnectionFormPortField();
}

class ConnectionFormHostField extends ConnectionFormFields<String> {
  const ConnectionFormHostField() : super._();

  @override
  String get name => 'host';

  @override
  String extract(ConnectionForm owner) => owner.host;

  @override
  ValidasiResult<String> validate(String? value) {
    final $errors = <ValidationError>[];
    if (value == null) {
      $errors.add(_Errors.required([name]));
    }
    if (value != null &&
        !RegExp(
          '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\$',
        ).hasMatch(value!)) {
      $errors.add(
        _Errors.regex(
          [name],
          '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\$',
          message: 'Enter a valid IP address or hostname',
        ),
      );
    }
    return _Result.from($errors, value);
  }

  @override
  Future<ValidasiResult<String>> validateAsync(String? value) async {
    return validate(value);
  }
}

class ConnectionFormPortField extends ConnectionFormFields<int> {
  const ConnectionFormPortField() : super._();

  @override
  String get name => 'port';

  @override
  int extract(ConnectionForm owner) => owner.port;

  @override
  ValidasiResult<int> validate(int? value) {
    final $errors = <ValidationError>[];
    if (value == null) {
      $errors.add(_Errors.required([name]));
    }
    if (value != null && (value! < 1 || value! > 65535)) {
      $errors.add(
        _Errors.between(
          [name],
          1,
          65535,
          message: 'Port must be between 1 and 65535',
        ),
      );
    }
    return _Result.from($errors, value);
  }

  @override
  Future<ValidasiResult<int>> validateAsync(int? value) async {
    return validate(value);
  }
}

class _ConnectionFormSchema extends ValidasiSchema<ConnectionForm> {
  const _ConnectionFormSchema();

  @override
  ConnectionForm allocate(ValidasiFieldReader<ConnectionForm> reader) {
    return ConnectionForm(
      host: reader.getValue(ConnectionFormFields.host) as String,
      port: reader.getValue(ConnectionFormFields.port) as int,
    );
  }
}

extension $ConnectionFormValidasi on ConnectionForm {
  ValidasiResult<ConnectionForm> validate() {
    final $errors = <ValidationError>[];
    // Field: host
    if (!RegExp(
      '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\$',
    ).hasMatch(host)) {
      $errors.add(
        _Errors.regex(
          ['host'],
          '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\$',
          message: 'Enter a valid IP address or hostname',
        ),
      );
    }
    // Field: port
    if ((port < 1 || port > 65535)) {
      $errors.add(
        _Errors.between(
          ['port'],
          1,
          65535,
          message: 'Port must be between 1 and 65535',
        ),
      );
    }
    if ($errors.isNotEmpty) {
      return ValidasiResult(errors: $errors, isValid: false);
    }
    return ValidasiResult(errors: const [], isValid: true, data: this);
  }

  Future<ValidasiResult<ConnectionForm>> validateAsync() async {
    final $errors = <ValidationError>[];
    // Field: host
    if (!RegExp(
      '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\$',
    ).hasMatch(host)) {
      $errors.add(
        _Errors.regex(
          ['host'],
          '^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\$',
          message: 'Enter a valid IP address or hostname',
        ),
      );
    }
    // Field: port
    if ((port < 1 || port > 65535)) {
      $errors.add(
        _Errors.between(
          ['port'],
          1,
          65535,
          message: 'Port must be between 1 and 65535',
        ),
      );
    }
    if ($errors.isNotEmpty) {
      return ValidasiResult(errors: $errors, isValid: false);
    }
    return ValidasiResult(errors: const [], isValid: true, data: this);
  }

  ValidasiResult<V> validateField<V>(ConnectionFormFields<V> field) {
    return field.validate(field.extract(this));
  }

  Future<ValidasiResult<V>> validateFieldAsync<V>(
    ConnectionFormFields<V> field,
  ) async {
    return field.validateAsync(field.extract(this));
  }
}

abstract final class _Errors {
  static ValidationError required(List<String> path, {String? message}) =>
      ValidationError(
        rule: 'Required',
        message: message ?? 'Field is required',
        path: path,
      );

  static ValidationError regex(
    List<String> path,
    String pattern, {
    String? message,
  }) => ValidationError(
    rule: 'Regex',
    message: message ?? 'Must match pattern "$pattern"',
    details: {'pattern': pattern},
    path: path,
  );

  static ValidationError between(
    List<String> path,
    num min,
    num max, {
    String? message,
  }) => ValidationError(
    rule: 'Between',
    message: message ?? 'Value must be between $min and $max',
    path: path,
  );
}

abstract final class _Result {
  static ValidasiResult<T> from<T>(List<ValidationError> errors, T? value) =>
      errors.isEmpty
      ? ValidasiResult(errors: const [], isValid: true, data: value)
      : ValidasiResult(errors: errors, isValid: false);

  static ValidasiResult<T> invalidSingle<T>(ValidationError error) =>
      ValidasiResult(errors: [error], isValid: false);
}
