import 'package:equatable/equatable.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object> get props => [];
}

class CustomerLoadRequested extends CustomerEvent {}

class CustomerAddRequested extends CustomerEvent {
  final String fullName;
  final String phoneNumber;
  final double balance;

  const CustomerAddRequested({
    required this.fullName,
    required this.phoneNumber,
    required this.balance,
  });

  @override
  List<Object> get props => [fullName, phoneNumber, balance];
}

class CustomerUpdateRequested extends CustomerEvent {
  final String customerId;
  final String fullName;
  final String phoneNumber;
  final double balance;

  const CustomerUpdateRequested({
    required this.customerId,
    required this.fullName,
    required this.phoneNumber,
    required this.balance,
  });

  @override
  List<Object> get props => [customerId, fullName, phoneNumber, balance];
}

class CustomerDeleteRequested extends CustomerEvent {
  final String customerId;

  const CustomerDeleteRequested(this.customerId);

  @override
  List<Object> get props => [customerId];
}