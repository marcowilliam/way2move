import 'package:fpdart/fpdart.dart';
import 'package:way2move/core/errors/app_failure.dart';
import '../entities/protocol.dart';
import '../repositories/protocol_repository.dart';

class GetActiveProtocols {
  final ProtocolRepository _repo;
  const GetActiveProtocols(this._repo);

  Future<Either<AppFailure, List<Protocol>>> call(String userId) =>
      _repo.getActiveProtocols(userId);
}
