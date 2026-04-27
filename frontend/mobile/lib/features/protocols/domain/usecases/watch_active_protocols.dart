import '../entities/protocol.dart';
import '../repositories/protocol_repository.dart';

class WatchActiveProtocols {
  final ProtocolRepository _repo;
  const WatchActiveProtocols(this._repo);

  Stream<List<Protocol>> call(String userId) =>
      _repo.watchActiveProtocols(userId);
}
