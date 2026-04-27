import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/app_failure.dart';
import '../entities/protocol.dart';

abstract class ProtocolRepository {
  /// Returns the user's currently-active protocol(s) — there can be more
  /// than one if the user follows multiple parallel prescriptions.
  /// Filters server-side on `status == active`. Today screen uses this.
  Future<Either<AppFailure, List<Protocol>>> getActiveProtocols(String userId);

  /// Live stream version. Today screen subscribes to this so a newly
  /// completed protocol disappears from the pin without a refresh.
  Stream<List<Protocol>> watchActiveProtocols(String userId);

  Future<Either<AppFailure, Protocol>> getProtocolById(String protocolId);

  Future<Either<AppFailure, Protocol>> createProtocol(Protocol protocol);

  Future<Either<AppFailure, Protocol>> updateProtocol(Protocol protocol);

  /// Mark the protocol completed. Called by the daily auto-flip when
  /// `endDate` passes, or manually if the user finishes early.
  Future<Either<AppFailure, Protocol>> completeProtocol(String protocolId);
}
