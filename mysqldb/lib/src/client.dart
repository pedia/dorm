part of mysql.client;

class State extends Flag {
  State(int v) : super(v);

  static const int unknown = 0x00;
  static const int sendAuthentication = 0x01;
  static const int logined = 0x02;
  static const int logout = 0x04;
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

  State state = State(State.unknown);

  PacketCreator? creator;
  Completer? queryCompleter;
  final Completer<State> _logined = Completer<State>();
  Future get logined => _logined.future;

  void init() {
    socket.listen(
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
      final _ = OkPacket.parse(p.inputStream, clientCapability);
      state.set(State.logined);
      _logined.complete(state);
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
        creator = null;

        if (queryCompleter != null) {
          queryCompleter!.complete(np);
        }
      }
    }
  }

  void onError(err, stackTrace) {
    print('got error $err');
  }

  ///
  Future query(String sql) {
    queryCompleter = Completer<ResultSet>();

    assert(state.has(State.logined));
    Packet.build(0, QueryCommand(sql: sql)).sendTo(socket);
    // this need dart 2.15
    creator = ResultSet.parse;

    return queryCompleter!.future;
  }

  Future<ResultSet> execute(String sql,
      [List<Object?> params = const []]) async {
    final completerAll = Completer<ResultSet>();

    // 1
    queryCompleter = Completer();
    Packet.build(0, PrepareStatement(sql: sql)).sendTo(socket);

    queryCompleter!.future.then((psr) async {
      // 2
      queryCompleter = Completer();
      Packet.build(
        0,
        ExecuteStatement(
          stmtId: (psr as PrepareStatementResponse).stmtId,
          values: params.map((e) => Field.of(e)).toList(),
        ),
      ).sendTo(socket);

      BinaryResultSet brs = await queryCompleter!.future;

      completerAll.complete(brs.rs);

      queryCompleter = null;
      Packet.build(0, CloseStatement(psr.stmtId)).sendTo(socket);
    });

    return completerAll.future;
  }
}
