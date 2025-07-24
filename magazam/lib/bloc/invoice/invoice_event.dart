import '../../models/invoice.dart';

abstract class InvoiceEvent {}

class InvoiceLoadRequested extends InvoiceEvent {
  final String? status;
  final String? customerId;

  InvoiceLoadRequested({this.status, this.customerId});
}

class InvoiceCreateRequested extends InvoiceEvent {
  final String customerId;
  final String invoiceNumber;
  final List<InvoiceItem> items;
  final double totalAmount;
  final InvoiceStatus status;

  InvoiceCreateRequested({
    required this.customerId,
    required this.invoiceNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
  });
}

class InvoiceUpdateRequested extends InvoiceEvent {
  final String invoiceId;
  final String? invoiceNumber;
  final String? customerId;
  final List<InvoiceItem>? items;
  final double? totalAmount;
  final InvoiceStatus? status;

  InvoiceUpdateRequested({
    required this.invoiceId,
    this.invoiceNumber,
    this.customerId,
    this.items,
    this.totalAmount,
    this.status,
  });
}

class InvoiceStatusUpdateRequested extends InvoiceEvent {
  final String invoiceId;
  final InvoiceStatus status;

  InvoiceStatusUpdateRequested({
    required this.invoiceId,
    required this.status,
  });
}

class InvoiceDeleteRequested extends InvoiceEvent {
  final String invoiceId;

  InvoiceDeleteRequested(this.invoiceId);
}