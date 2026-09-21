/// Application-supplied validation messages used by built-in validators.
///
/// The package ships no translated catalogs. Applications can implement this
/// interface with their existing localization system and pass it to
/// `SmartForm.messages`.
abstract interface class SmartFormMessages {
  /// Required-value message.
  String get required;

  /// Invalid-email message.
  String get invalidEmail;

  /// Exact-length message.
  String exactLength(int expected);

  /// Minimum-length message.
  String minimumLength(int minimum);

  /// Maximum-length message.
  String maximumLength(int maximum);

  /// Pattern-mismatch message.
  String get invalidPattern;

  /// Invalid-number message.
  String get invalidNumber;

  /// Minimum-number message.
  String minimumNumber(num minimum);

  /// Maximum-number message.
  String maximumNumber(num maximum);

  /// Cross-field mismatch message.
  String get valuesDoNotMatch;
}

/// Backwards-compatible fallback messages, not a localization catalog.
final class SmartDefaultFormMessages implements SmartFormMessages {
  /// Creates fallback messages.
  const SmartDefaultFormMessages();

  @override
  String get required => 'This field is required.';

  @override
  String get invalidEmail => 'Enter a valid email address.';

  @override
  String exactLength(int expected) =>
      'Must contain exactly $expected characters.';

  @override
  String minimumLength(int minimum) =>
      'Must contain at least $minimum characters.';

  @override
  String maximumLength(int maximum) =>
      'Must contain at most $maximum characters.';

  @override
  String get invalidPattern => 'Enter a value in the required format.';

  @override
  String get invalidNumber => 'Enter a valid number.';

  @override
  String minimumNumber(num minimum) =>
      'Enter a value greater than or equal to $minimum.';

  @override
  String maximumNumber(num maximum) =>
      'Enter a value less than or equal to $maximum.';

  @override
  String get valuesDoNotMatch => 'Values do not match.';
}
