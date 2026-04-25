part of 'counter_bloc.dart';

class CounterState extends Equatable {
  const CounterState({this.counter = 0});

  final int counter;

  @override
  List<Object> get props => [counter];
}
