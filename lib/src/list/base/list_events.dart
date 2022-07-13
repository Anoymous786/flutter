import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Base class for all list events.
///
/// [F] - the filter type.
@immutable
abstract class ListEvent<F> extends Equatable {
  final F? filter;

  const ListEvent([this.filter]);
}

/// Event for indicating that initial list load needs to be performed.
///
/// [F] - the filter type.
class LoadList<F> extends ListEvent<F> {
  const LoadList([F? filter]) : super(filter);

  @override
  List<Object?> get props => [filter];

  @override
  String toString() => 'LoadList: $filter';
}

/// Event for indicating that list needs to be refreshed.
///
/// [F] - the filter type.
class RefreshList<F> extends ListEvent<F> {
  const RefreshList([F? filter]) : super(filter);

  @override
  List<Object?> get props => [filter];

  @override
  String toString() => 'RefreshList: $filter';
}
