import 'package:bloc/bloc.dart';
import 'package:flutter_bloc_patterns/base_list.dart';
import 'package:flutter_bloc_patterns/paged_filter_list.dart';
import 'package:flutter_bloc_patterns/src/common/view_state.dart';
import 'package:flutter_bloc_patterns/src/list/paged/page.dart';
import 'package:flutter_bloc_patterns/src/list/paged/paged_list.dart';
import 'package:flutter_bloc_patterns/src/list/paged/paged_list_events.dart';
import 'package:flutter_bloc_patterns/src/list/paged/paged_list_repository.dart';

/// A list BLoC with pagination and filtering.
///
/// Designed to collaborate with [ViewStateBuilder] for displaying data.
///
/// Call [loadFirstPage] to fetch first page of data. This is where filter
/// value can be set as well as the page size and these values cannot be changed
/// when loading the next page.
/// Call [loadNextPage] to fetch next page of data.
///
/// [T] - the type of list elements.
/// [F] - the type of filter.
class PagedListFilterBloc<T, F> extends Bloc<PagedListEvent, ViewState> {
  static const defaultPageSize = 10;

  final PagedListFilterRepository<T, F> _pagedFilterRepository;
  F _filter;

  PagedListFilterBloc(PagedListFilterRepository<T, F> pagedListFilterRepository)
      : assert(pagedListFilterRepository != null),
        this._pagedFilterRepository = pagedListFilterRepository;

  @override
  ViewState get initialState => Initial();

  List<T> get _currentElements =>
      (state is Success) ? (state as Success).data.elements : [];

  Page _page;

  F get filter => _filter;

  /// Loads elements using the given [filter] and [pageSize]. When no size
  /// is given [_defaultPageSize] is used.
  ///
  /// It's most suitable for initial data fetch or for retry action when
  /// the first fetch fails.
  void loadFirstPage({int pageSize = defaultPageSize, F filter}) {
    _page = Page.first(size: pageSize);
    _filter = filter;
    add(LoadPage(_page, filter: _filter));
  }

  /// Loads next page. When no page has been loaded before the first one is
  /// loaded with the default page size [_defaultPageSize].
  void loadNextPage() {
    _page = _page?.next() ?? Page.first(size: defaultPageSize);
    add(LoadPage(_page, filter: _filter));
  }

  @override
  Stream<ViewState> mapEventToState(PagedListEvent event) async* {
    if (event is LoadPage) {
      yield* _mapLoadPage(event.page, event.filter);
    }
  }

  Stream<ViewState> _mapLoadPage(Page page, F filter) async* {
    try {
      yield* _emitLoadingWhenFirstPage(page);
      final List<T> pageElements =
          await _pagedFilterRepository.getBy(page, filter);
      yield* (pageElements.isEmpty)
          ? _emitEmptyPageLoaded(page)
          : _emitNextPageLoaded(page, pageElements);
    } on PageNotFoundException catch (_) {
      yield* _emitEmptyPageLoaded(page);
    } catch (e) {
      yield Failure(e);
    }
  }

  Stream<ViewState> _emitLoadingWhenFirstPage(Page page) async* {
    if (page.isFirst) {
      yield Loading();
    }
  }

  Stream<ViewState> _emitEmptyPageLoaded(Page page) async* {
    yield (_isFirst(page))
        ? Empty()
        : Success(PagedList<T>(_currentElements, hasReachedMax: true));
  }

  bool _isFirst(Page page) => page.number == 0;

  Stream<ViewState> _emitNextPageLoaded(
    Page page,
    List<T> pageElements,
  ) async* {
    final List<T> allElements = _currentElements + pageElements;
    yield Success(
      PagedList<T>(allElements, hasReachedMax: page.size > pageElements.length),
    );
  }
}