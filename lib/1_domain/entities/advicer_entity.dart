import 'package:equatable/equatable.dart';

class AdvicerEntity extends Equatable {
  const AdvicerEntity({
    required this.advice,
    required this.id,
  });

  final String advice;
  final int id;

  @override
  List<Object?> get props => [advice, id];
}
