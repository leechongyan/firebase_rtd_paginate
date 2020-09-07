part of 'pagination_bloc.dart';

@immutable
abstract class PaginationState extends Equatable{
}

class PaginationInitial extends PaginationState {

  @override
  List<Object> get props => [];
}

class PaginationError extends PaginationState {
  final Exception error;
  PaginationError({@required this.error});

  @override
  List<Object> get props => [error];
}

class PaginationLoaded<T> extends PaginationState {
  PaginationLoaded({
    @required this.data,
  });

  final List<T> data;

  PaginationLoaded copyWith<T>({
    List<T> data,
  }) {
    return PaginationLoaded(
      data: data ?? this.data,
    );
  }

  @override
  List<Object> get props => [data];
}