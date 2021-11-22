part of mysql.client;

class State extends Flag {
  State(int v) : super(v);

  static const int unknown = 0x00;
  static const int sendAuthentication = 0x01;
  static const int logined = 0x02;
  static const int logout = 0x04;
  // switch user
}

typedef PacketCreator = Packet Function(InputStream);

///
class Client {
  final Socket socket;
  final String user;
  final String password;
  final String? db;
  final Capability clientCapability = Capability.kClientDefault56;

  Client({
    required this.socket,
    required this.user,
    required this.password,
    this.db,
  });

  static Future<Client> connect({
    required String address,
    required String user,
    required String password,
    String? db,
  }) async {
    final arr = address.split(':');
    final socket = await Socket.connect(arr[0], int.parse(arr[1]));
    return Client(
      socket: socket,
      user: user,
      password: password,
      db: db,
    )..init();
  }

  late Capability serverCapability;
  late StreamSubscription subscription;
  late Uint8List scramble;
  int packetId = -1;
  int get nextPacketId => ++packetId;

  State state = State(State.unknown);

  /// Create instance with Type via dart:mirrors.
  // Type? npt;
  PacketCreator? creator;
  Completer<ResultSet>? queryCompleter;
  final Completer<State> _logined = Completer<State>();
  Future get logined => _logined.future;

  void init() {
    subscription = socket.listen(
      onData,
      onError: onError,
      cancelOnError: true,
    );
  }

  void login(data) {
    Packet p = Packet.parse(InputStream.from(data), clientCapability);
    if (p is ErrorPacket) {
      print(p.toString());
      socket.close();
      return;
    }

    packetId = p.packetId!;

    if (!state.has(State.sendAuthentication)) {
      final hs = Handshake.parse(p.inputStream);

      final ca = Packet.build(
        p.packetId! + 1,
        ClientAuthentication(
          hs,
          user: user,
          password: password,
          db: db,
          options: {
            '_os': 'osx10.16',
            '_client_name': 'libmysql',
            '_pid': '67393',
            '_client_version': '5.6.50',
            '_platform': 'x86_64',
            'program_name': 'mysql',
          },
          clientCapability: clientCapability,
        ),
      );

      ca.sendTo(socket);
      state.set(State.sendAuthentication);
    } else {
      final ok = OkPacket.parse(p.inputStream, clientCapability);
      state.set(State.logined);
      _logined.complete(state);

      // Packet.build(0, Query(sql: 'show databases')).sendTo(socket);
      // Packet.build(0, Query(sql: 'show variables like "%name"')).sendTo(socket);
      // npt = ResultSet;
    }
  }

  void onData(Uint8List data) {
    if (debug) print('s : ${hexed(data)}');

    if (!state.has(State.logined)) {
      login(data);
    } else {
      //
      final input = InputStream.fromList(data);
      final bytes = input.peeks(5);

      // check OkPacket
      if (input.byteLeft == 11 && bytes[4] == Packet.ok) {
        Packet.parse(input);
        queryCompleter?.complete(ResultSet([], []));

        return;
      }

      // check ErrorPacket
      if (bytes[4] == Packet.error) {
        final err = Packet.parse(input);
        if (queryCompleter != null) {
          queryCompleter!.completeError(err);
        } else {
          throw err;
        }
        return;
      }

      if (creator != null) {
        // Create instance from Type via 5
        // final np = reflectClass(npt!).newInstance(
        //   Symbol('parse'),
        //   [input],
        // ).reflectee as Packet;
        final np = creator!(input);

        if (queryCompleter != null && np is ResultSet) {
          queryCompleter!.complete(np);
        }
      }
    }
  }

  void onError(err, stackTrace) {
    print('got error $err');
  }

  Future<ResultSet> query(String sql) {
    queryCompleter = Completer<ResultSet>();

    assert(state.has(State.logined));
    Packet.build(0, QueryCommand(sql: sql)).sendTo(socket);
    // this need dart 2.15
    creator = ResultSet.parse;

    return queryCompleter!.future;
  }
}
