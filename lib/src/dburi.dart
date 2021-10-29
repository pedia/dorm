part of dorm;

///
/// Like jdbcuri, wrap db connection string.
/// eg:
///   sqlite:///file.db
///   sqlite:///memory
///   mysql://root:38e423hs@127.0.0.1/test?encoding=utf-8
///
class DbUri {
  final String scheme;
  final String? host;

  /// Port is nullable.
  final int? port;
  final String database;
  final String? user;
  final String? password;

  /// [args] always like [queryParameters] of [Uri].
  final Map<String, dynamic> args;

  DbUri({
    required this.scheme,
    this.host,
    this.port,
    required this.database,
    this.user,
    this.password,
    this.args = const <String, String>{},
  });

  /// Not support escape
  @override
  String toString() => [
        scheme,
        '://',
        if (user != null) user,
        if (user != null && password != null) ':',
        if (user != null && password != null) password,
        if (user != null) '@',
        if (host != null) host,
        if (port != null) ':',
        if (port != null) port,
        '/',
        database,
        if (args.isNotEmpty) '?',
        if (args.isNotEmpty)
          args.entries.map((e) => '${e.key}=${e.value}').toList().join(''),
      ].join('');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DbUri &&
        scheme == other.scheme &&
        host == other.host &&
        port == other.port &&
        database == other.database &&
        user == other.user &&
        password == other.password;
    // TODO: collection equality
    //  &&
    //  args == other.args;
  }

  static DbUri parse(String uri) {
    final res = Uri.parse(uri);

    if (res.scheme == 'sqlite') {
      return DbUri(
        scheme: res.scheme,
        database: res.path.substring(1),
        args: res.queryParameters,
      );
    } else {
      final arr = res.userInfo.split(':');
      return DbUri(
        scheme: res.scheme,
        host: res.host,
        port: res.port == 0 ? null : res.port,
        database: res.path.substring(1),
        user: arr.isNotEmpty ? arr[0] : null,
        password: arr.length > 1 ? arr[1] : null,
        args: res.queryParameters,
      );
    }
  }
}
