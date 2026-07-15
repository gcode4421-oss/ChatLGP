/// الرسائل العربية لمكتبة timeago

import 'package:timeago/timeago.dart';

class ArMessages implements LookupMessages {
  @override
  String prefixAgo() => 'منذ';
  @override
  String prefixFromNow() => 'بعد';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'لحظات';
  @override
  String aboutAMinute(int minutes) => 'دقيقة';
  @override
  String minutes(int minutes) => '$minutes دقيقة';
  @override
  String aboutAnHour(int minutes) => 'ساعة';
  @override
  String hours(int hours) => '$hours ساعة';
  @override
  String aDay(int hours) => 'يوم';
  @override
  String days(int days) => '$days يوم';
  @override
  String aboutAMonth(int days) => 'شهر';
  @override
  String months(int months) => '$months شهر';
  @override
  String aboutAYear(int year) => 'سنة';
  @override
  String years(int years) => '$years سنة';
  @override
  String wordSeparator() => ' ';
}
