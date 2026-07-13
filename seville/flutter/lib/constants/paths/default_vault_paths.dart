abstract final class DefaultVaultPaths {
  static const cortex = 'cortex';
}

abstract final class DefaultTimelineVaultPaths {
  static const past = 'time/concept/past';
  static const now = 'time/concept/now';
  static const future = 'time/concept/future';
  static const today = 'time/concept/today';
  static const bce = 'time/era/bce';
  static const ce = 'time/era/ce';
  static const etc = 'science/mathematics/logic/concept/etc';
  static const ivBceMillennium = 'time/millennium/bce/iv-bce-millennium';
  static const iiiBceMillennium = 'time/millennium/bce/iii-bce-millennium';
  static const iiBceMillennium = 'time/millennium/bce/ii-bce-millennium';
  static const iBceMillennium = 'time/millennium/bce/i-bce-millennium';
  static const iMillennium = 'time/millennium/ce/i-millennium';
  static const iiMillennium = 'time/millennium/ce/ii-millennium';
  static const iiiMillennium = 'time/millennium/ce/iii-millennium';
  static const xxvBceCentury = 'time/century/bce/xxv-bce-century';
  static const iBceCentury = 'time/century/bce/i-bce-century';
  static const iCentury = 'time/century/ce/i-century';
  static const xxCentury = 'time/century/ce/xx-century';
  static const xxiCentury = 'time/century/ce/xxi-century';
  static const xxiiCentury = 'time/century/ce/xxii-century';
  static const zeroes = 'time/decade/zeroes';
  static const tens = 'time/decade/tens';
  static const twenties = 'time/decade/twenties';
  static const thirties = 'time/decade/thirties';
  static const forties = 'time/decade/forties';
  static const fifties = 'time/decade/fifties';
  static const sixties = 'time/decade/sixties';
  static const seventies = 'time/decade/seventies';
  static const eighties = 'time/decade/eighties';
  static const nineties = 'time/decade/nineties';
  static const year2019 = 'time/year/2019';
  static const year2020 = 'time/year/2020';
  static const year2021 = 'time/year/2021';
  static const year2022 = 'time/year/2022';
  static const year2023 = 'time/year/2023';
  static const year2024 = 'time/year/2024';
  static const year2025 = 'time/year/2025';
  static const year2026 = 'time/year/2026';
  static const year2027 = 'time/year/2027';
  static const year2028 = 'time/year/2028';
  static const year2029 = 'time/year/2029';
  static const year2030 = 'time/year/2030';
  static const q1 = 'time/repeated/quarter/q1';
  static const q2 = 'time/repeated/quarter/q2';
  static const q3 = 'time/repeated/quarter/q3';
  static const q4 = 'time/repeated/quarter/q4';
  static const january = 'time/repeated/month/january';
  static const february = 'time/repeated/month/february';
  static const march = 'time/repeated/month/march';
  static const april = 'time/repeated/month/april';
  static const may = 'time/repeated/month/may';
  static const june = 'time/repeated/month/june';
  static const july = 'time/repeated/month/july';
  static const august = 'time/repeated/month/august';
  static const september = 'time/repeated/month/september';
  static const october = 'time/repeated/month/october';
  static const november = 'time/repeated/month/november';
  static const december = 'time/repeated/month/december';

  static String week(int year, String month, int weekOfMonth) =>
      'time/week/$year/$month/week-$weekOfMonth';
}
