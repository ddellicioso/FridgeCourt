import '../models/case.dart';

/// Sentences handed down after a GUILTY verdict from the jury (or the
/// 24-hour timeout), grouped by the crime's severity. Picked at random,
/// excluding whatever this same person's sentence was last time, so it
/// doesn't repeat twice in a row (see CaseStore._pickSentence).
const Map<Severity, List<String>> sentencePool = {
  Severity.minor: [
    'Must do the dishes for 2 days.',
    'Has to restock whatever was taken.',
    'Banned from the good snack shelf for a week.',
    'Owes the house a round of coffee runs.',
    'Must leave a formal written apology on the fridge.',
  ],
  Severity.medium: [
    'Must do the dishes for a week.',
    'Has to cook dinner for the house once.',
    'Banned from the good snack shelf for two weeks.',
    'Owes everyone a replacement snack of their choice.',
    'Must do a full fridge clean-out this weekend.',
  ],
  Severity.major: [
    'Must do the dishes for two full weeks.',
    'Has to cook dinner for the house twice.',
    'Banned from the good snack shelf for a month.',
    'Must do all grocery runs for the next two weeks.',
    'Owes the house a full restock of whatever was taken, plus interest (snacks).',
  ],
};

/// Lighter sentences for a GUILTY PLEA — the "plea deal," always a step
/// down from the full jury sentence for the same severity.
const Map<Severity, List<String>> pleaDealPool = {
  Severity.minor: [
    'Plea deal: dishes for 1 day.',
    'Plea deal: a sincere apology, case closed.',
    'Plea deal: replace what was taken, no further punishment.',
  ],
  Severity.medium: [
    'Plea deal: dishes for 3 days.',
    'Plea deal: replace what was taken plus a small treat for the house.',
    'Plea deal: one dinner cooked for the house.',
  ],
  Severity.major: [
    'Plea deal: dishes for a week.',
    'Plea deal: one grocery run plus a full restock.',
    'Plea deal: one dinner cooked for the house, no dessert excuses.',
  ],
};
