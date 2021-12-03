part of mysql.server;

///
class Server {
  static Future<Server> start(String address, Database db) async {
    final arr = address.split(':');
    return ServerSocket.bind(arr[0], int.parse(arr[1])).then<Server>(
      (socket) => Server(socket, db).._init(),
    );
  }

  final Database db;
  final Capability capability = Capability.kServerDefault; // 5.7
  final String version = '5.7.36';
  final ServerSocket socket;
  final Password authPlugin;
  final clients = <Client>[];

  Server(this.socket, this.db, [this.authPlugin = const NativePassword()]);

  String get address => socket.address.address;

  ServerStatus status = ServerStatus.defaultStatus;
  late CachingSha2Password passwordStore;
  int threadId = 0;
  int get nextThreadId => ++threadId;

  void _init() {
    socket.listen(onNewClient);

    CachingSha2Password.loadAsync('passwd').then(
      (store) => passwordStore = store,
    );
  }

  void onNewClient(Socket clientSocket) {
    clients.add(Client(clientSocket, nextThreadId, this)..init());
  }

  void remove(Client c) => clients.remove(c);

  bool validate(String user, Uint8List rnd, Uint8List scramble) {
    Uint8List? known = passwordStore.find(user);
    if (known == null) return false;

    // empty password
    if (scramble.isEmpty && known.isEmpty) {
      return true;
    }

    if (scramble.length != authPlugin.digestLength) {
      return false;
    }

    return authPlugin.validate(rnd, scramble, known);
  }
}

///
class Client {
  final Socket socket;
  final int threadId;
  final Server server;
  Client(this.socket, this.threadId, this.server);

  late Uint8List rnd;
  late Capability clientCapability;

  void init() {
    socket.listen(
      onData,
      onDone: () {
        if (verbose) print('Client $threadId closed.');
        server.remove(this);
      },
    );

    rnd = Salt().generate();
    if (debug) print('rnd:${hexed(rnd)}');

    // Send first packet.
    Packet.build(
      0,
      Handshake(
        threadId: threadId,
        version: server.version,
        scramble: rnd,
        authPlugin: server.authPlugin.name,
        serverCapability: Capability(Capability.allValue & ~Capability.ssl),
        serverCharset: Charset.utf8mb4,
        serverStatus: server.status.value,
      ),
    ).sendTo(socket);
  }

  void addRaw(Uint8List buf) {
    if (debug) print('s : ${hexed(buf)}');

    socket.add(buf);

    /// fixed: nc -z cause crash
    socket.flush().then((_) => null);
  }

  bool handshaked = false;

  void onData(Uint8List data) {
    if (debug) print('c : ${hexed(data)}');

    if (!handshaked) {
      final p = Packet.parse(InputStream.from(data), server.capability);

      final sa = ServerAuthentication.parse(p.inputStream);
      handshaked = true;
      if (debug) print('pw: ${hexed(sa.scramble)}');

      //
      bool logined = server.validate(sa.user, rnd, sa.scramble);
      clientCapability = sa.clientFlag;
      if (verbose) {
        print('Client $threadId user:${sa.user}, db:${sa.db}, '
            'logined:$logined');
      }

      Packet.build(
        p.packetId! + 1,
        logined
            ? OkPacket(serverStatus: server.status.value)
            : ErrorPacket(
                code: 1045,
                state: '28000',
                message:
                    'Access denied for user \'${sa.user}\'@\'${server.address}\''
                    ' (using password: YES)',
              ),
      ).sendTo(socket);
    } else {
      final p = Packet.parse(InputStream.from(data), server.capability);

      final cmd = CommandPacket.parse(p.inputStream);
      if (verbose) print('MySQL got: $cmd');

      if (cmd.command == Command.quit) {
        socket.destroy();
        socket.close().then((_) => null);
      } else {
        server.db.handle(cmd).then((answer) {
          if (answer is ResultSet) {
            addRaw(answer.encode());
          } else {
            addRaw(Packet.build(p.packetId! + 1, answer).encode());
          }
        }).catchError((err) {
          if (verbose) {
            print('Handle $cmd failed: $err');
          }
          addRaw(
              ErrorPacket(code: 30000, state: '55000', message: err.toString())
                  .encode());
        });
        return;
      }
    }
  }
}
