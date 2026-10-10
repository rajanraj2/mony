class SmsRule {
  final String id;
  final String name;
  final String senderPattern;
  final String messagePattern;
  final String direction; // income, expense
  final String? defaultCategoryId;
  final String? accountHint;
  final bool enabled;
  final int sortOrder;

  const SmsRule({
    required this.id,
    required this.name,
    required this.senderPattern,
    required this.messagePattern,
    required this.direction,
    this.defaultCategoryId,
    this.accountHint,
    this.enabled = true,
    this.sortOrder = 0,
  });

  SmsRule copyWith({
    String? id,
    String? name,
    String? senderPattern,
    String? messagePattern,
    String? direction,
    String? defaultCategoryId,
    String? accountHint,
    bool? enabled,
    int? sortOrder,
  }) {
    return SmsRule(
      id: id ?? this.id,
      name: name ?? this.name,
      senderPattern: senderPattern ?? this.senderPattern,
      messagePattern: messagePattern ?? this.messagePattern,
      direction: direction ?? this.direction,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      accountHint: accountHint ?? this.accountHint,
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
