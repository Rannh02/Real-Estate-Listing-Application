import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'counter_event.dart';
part 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<CounterIncremented>((event, emit) {
      emit(CounterState(counter: state.counter + 1));
    });
    on<CounterDecremented>((event, emit) {
      emit(CounterState(counter: state.counter - 1));
    });
  }
}
