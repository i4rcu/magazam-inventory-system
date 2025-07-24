import 'package:equatable/equatable.dart';
import '../../models/customer.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<Customer> customers;

  const CustomerLoaded(this.customers);

  @override
  List<Object> get props => [customers];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object> get props => [message];
}

class CustomerOperationSuccess extends CustomerState {
  final String message;
  final List<Customer> customers;

  const CustomerOperationSuccess(this.message, this.customers);

  @override
  List<Object> get props => [message, customers];
}