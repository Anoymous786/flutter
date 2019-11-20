import 'package:flutter_bloc_patterns/paged_list.dart';
import 'package:flutter_bloc_patterns/src/common/view_state.dart';
import 'package:flutter_bloc_patterns/src/list/paged/paged_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../util/bdd.dart';
import '../../util/bloc_state_assertion.dart';
import 'paged_list_repository_mock.dart';

void main() {
  PagedListBloc<int> bloc;
  PagedListRepository<int> repository;

  void loadingFirstPage() => bloc.loadFirstPage(pageSize: 3);

  void loadingNextPage() => bloc.loadNextPage();

  group('repository without elements', () {
    setUp(() {
      repository = InMemoryPagedListRepository<int>([]);
      bloc = PagedListBloc<int>(repository);
    });

    test('should emit list loaded empty when first page contains no elements',
        () {
      when(loadingFirstPage);
      then(() {
        withBloc(bloc).expectStates([
          Initial(),
          Loading(),
          Empty(),
        ]);
      });
    });

    tearDown(() {
      bloc.close();
    });
  });

  group('repository with elements', () {
    const firstPage = [0, 1, 2];
    const secondPage = [3, 4, 5];
    const thirdPage = [6];
    final someData = firstPage + secondPage + thirdPage;

    setUp(() {
      repository = InMemoryPagedListRepository<int>(someData);
      bloc = PagedListBloc<int>(repository);
    });

    test(
        'should emit list loaded with first page elements when loading first page',
        () {
      when(loadingFirstPage);

      then(() {
        withBloc(bloc).expectStates([
          Initial(),
          Loading(),
          Success(PagedList(firstPage, hasReachedMax: false)),
        ]);
      });
    });

    test(
        'should emit list loaded with first, first and second page elements when loading two pages',
        () {
      when(() {
        loadingFirstPage();
        loadingNextPage();
      });

      then(() {
        withBloc(bloc).expectStates([
          Initial(),
          Loading(),
          Success(PagedList(firstPage, hasReachedMax: false)),
          Success(PagedList(firstPage + secondPage, hasReachedMax: false)),
        ]);
      });
    });

    test(
        'should emit list loaded with first, first and second and first, second and third page elements when loading three pages',
        () {
      when(() {
        loadingFirstPage();
        loadingNextPage();
        loadingNextPage();
      });

      then(() {
        withBloc(bloc).expectStates([
          Initial(),
          Loading(),
          Success(PagedList(firstPage, hasReachedMax: false)),
          Success(PagedList(firstPage + secondPage, hasReachedMax: false)),
          Success(PagedList(
            firstPage + secondPage + thirdPage,
            hasReachedMax: true,
          )),
        ]);
      });
    });

    test(
        'should emit list loaded with hasReachedMax when there are no more pages',
        () {
      when(() {
        loadingFirstPage();
        loadingNextPage();
        loadingNextPage();
        loadingNextPage();
      });

      then(() {
        withBloc(bloc).expectStates([
          Initial(),
          Loading(),
          Success(PagedList(firstPage, hasReachedMax: false)),
          Success(PagedList(firstPage + secondPage, hasReachedMax: false)),
          Success(
            PagedList(
              firstPage + secondPage + thirdPage,
              hasReachedMax: true,
            ),
          ),
        ]);
      });
    });

    tearDown(() {
      bloc.close();
    });
  });

  group('failing repository', () {
    group('repository failing with exception', () {
      final exception = Exception('Ooopsi!');
      setUp(() {
        repository = FailingPagedRepository(exception);
        bloc = PagedListBloc<int>(repository);
      });

      test('should emit list not loaded when exception occurs', () {
        when(loadingFirstPage);
        then(() {
          withBloc(bloc).expectStates([
            Initial(),
            Loading(),
            Failure(exception),
          ]);
        });
      });

      tearDown(() {
        bloc.close();
      });
    });

    group('repository failing with error', () {
      final error = AssertionError();
      setUp(() {
        repository = FailingPagedRepository(error);
        bloc = PagedListBloc<int>(repository);
      });

      test('should emit list not loaded when error occurs', () {
        when(loadingFirstPage);
        then(() {
          withBloc(bloc).expectStates([
            Initial(),
            Loading(),
            Failure(error),
          ]);
        });
      });

      tearDown(() {
        bloc.close();
      });
    });

    group('repository unable to find page', () {
      final pageNotFound = PageNotFoundException(0);
      setUp(() {
        repository = FailingPagedRepository(pageNotFound);
        bloc = PagedListBloc<int>(repository);
      });

      test('should emit list loaded empty when first page was not found', () {
        when(loadingFirstPage);
        then(() {
          withBloc(bloc).expectStates([
            Initial(),
            Loading(),
            Empty(),
          ]);
        });
      });

      tearDown(() {
        bloc.close();
      });
    });
  });
}
