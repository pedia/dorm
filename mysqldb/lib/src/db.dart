part of mysql.server;

///
abstract class Database {
  /// Query SQL, same as handle(QueryCommand)
  Future<ResultSet> query(String sql);

  ///
  Future<Packet> handle(CommandPacket cmd);
}
