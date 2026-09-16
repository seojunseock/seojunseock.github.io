/// One reception-desk record: a guest's envelope, converted to a numbered
/// ledger row. Amounts are stored in 만원 (10,000-won) units, matching how
/// the receptionist reads the cash out of the envelope.
class GiftEntry {
  final int no;
  String name;
  int amount;
  int tickets;

  GiftEntry({
    required this.no,
    required this.name,
    required this.amount,
    required this.tickets,
  });

  Map<String, dynamic> toJson() => {
        'no': no,
        'name': name,
        'amount': amount,
        'tickets': tickets,
      };

  factory GiftEntry.fromJson(Map<String, dynamic> json) => GiftEntry(
        no: json['no'] as int,
        name: json['name'] as String,
        amount: json['amount'] as int,
        tickets: json['tickets'] as int,
      );
}
