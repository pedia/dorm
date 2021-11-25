import 'package:mysqldb/impl.dart';
import 'package:test/test.dart';
import 'hexstring.dart';

main() {
  test('HandshakeTest', () {
    final p = Handshake(
      threadId: 34,
      version: '8.0.22',
      scramble: bytesFromHexed(
        '3d07 3340 0b25 644a 2b43 2160 131e 4c5a 223f 7e3a',
      ),
      authPlugin: 'caching_sha2_password',
      serverCharset: Charset.utf8mb4,
      serverStatus: ServerStatus.statusAutocommit,
      serverCapability: Capability(Capability.allValue & ~Capability.ssl),
    );
    final body = p.encode();

    final p2 = Handshake.parse(InputStream.from(body));
    expect(p2.authPlugin, p.authPlugin);
    expect(p2.version, p.version);
    expect(p2.scramble, p.scramble);
    expect(p2.threadId, p.threadId);
    expect(p2.serverCharset, p.serverCharset);
    expect(p2.serverStatus, p.serverStatus);
    expect(p2.serverCapability, p.serverCapability);
  });
}
