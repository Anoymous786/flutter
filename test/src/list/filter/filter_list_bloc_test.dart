import 'package:flutter_bloc_patterns/src/list/filter/filter_list_bloc.dart';
import 'package:flutter_bloc_patterns/src/view/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util/bdd.dart';
import '../../util/bloc_state_assertion.dart';
import 'filter_list_repository_mock.dart';

void main() {
  const _someData = [1, 2, 3];
  const _notMatchingFilter = 0;
  const _matchingFilter = 1;
  const _matchingItems = [1];

  late FilterListBloc<int, int> bloc;

  void loadingItems({int? filter}) => bloc.loadItems(filter: filter);

  void refreshingItems({int? filter}) => bloc.refreshItems(filter: filter);

  group('empty repository', () {
    setUp(() {
      bloc = FilterListBloc(InMemoryFilterRepository());
    });

    test('should emit [$Loading, $Empty] state when no filter is set',
        () async {
      when(loadingItems);
      await then(
        () async => withBloc(bloc).expectStates(
          const [Loading(), Empty()],
        ),
      );
    });

    test(
        'should emit[$Loading, $Empty] when filter that matches no items is set',
        () async {
      when(() => loadingItems(filter: _notMatchingFilter));
      await then(
        () async => withBloc(bloc).expectStates(
          const [Loading(), Empty()],
        ),
      );
    });

    tearDown(() {
      bloc.close();
    });
  });

  group('repository with items', () {
    setUp(() {
      bloc = FilterListBloc(
        InMemoryFilterRepository(_someData),
      );
    });

    test(
        'should emit [$Loading, $Success] with all items when no filter is set',
        () async {
      when(loadingItems);
      await then(
        () async => withBloc(bloc).expectStates(
          const [Loading(), Success(_someData)],
        ),
      );
    });

    test('should emit [$Loading, $Success] with items matching the filter',
        () async {
      when(() => loadingItems(filter: _matchingFilter));
      await then(
        () async => withBloc(bloc).expectStates(
          const [
            Loading(),
            Success(_matchingItems),
          ],
        ),
      );
    });

    test('should emit [$Loading, $Empty] when no items matches the filter',
        () async {
      when(() => loadingItems(filter: _notMatchingFilter));
      await then(
        () => withBloc(bloc).expectStates(
          const [Loading(), Empty()],
        ),
      );
    });

    test(
        'should emit [$Loading, $Empty, $Refreshing, $Success] when refreshing with matching filter',
        () async {
      when(() => loadingItems(filter: _notMatchingFilter));
      await then(
        () async => withBloc(bloc).expectStates(const [Loading(), Empty()]),
      );

      when(() => refreshingItems(filter: _matchingFilter));
      await then(
        () async => withBloc(bloc).expectStates(const [
          Refreshing<List<int>>([]),
          Success<List<int>>(_matchingItems),
        ]),
      );
    });

    test('should include loaded items when refreshing', () async {
      when(() => loadingItems(filter: _matchingFilter));
      await then(
        () async => withBloc(bloc).expectStates(const [
          Loading(),
          Success(_matchingItems),
        ]),
      );

      when(() => refreshingItems(filter: _notMatchingFilter));
      await then(
        () async => withBloc(bloc).expectStates(const [
          Refreshing(_matchingItems),
          Empty(),
        ]),
      );
    });

    tearDown(() {
      bloc.close();
    });
  });

  group('failing repository with exception', () {
    final exception = Exception('Oh no, I failed!');

    setUp(() {
      bloc = FilterListBloc(FailingFilterRepository(exception));
    });

    test('should emit [$Loading, $Failure] when no filter is set', () async {
      when(loadingItems);
      await then(
        () async => withBloc(bloc).expectStates(
          [const Loading(), Failure(exception)],
        ),
      );
    });

    test('should emit [$Loading, $Failure] when filter is set', () async {
      when(() => loadingItems(filter: _notMatchingFilter));
      await then(
        () async => withBloc(bloc).expectStates(
          [const Loading(), Failure(exception)],
        ),
      );
    });

    tearDown(() {
      bloc.close();
    });
  });

  group('failing repository with error', () {
    final error = Error();

    setUp(() {
      bloc = FilterListBloc(FailingFilterRepository(error));
    });

    test('should emit [$Loading, $Failure] when error occurs', () async {
      when(() => loadingItems());
      await then(
        () async => withBloc(bloc).expectStates(
          [const Loading(), Failure(error)],
        ),
      );
    });

    tearDown(() {
      bloc.close();
    });
  });
}
