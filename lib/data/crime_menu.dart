import '../models/case.dart';

/// One entry in the "file a crime" menu. Picking one (after picking who
/// did it) files the case immediately — no typing required, which is
/// what keeps filing a report to 3 taps or fewer.
class CrimeDef {
  final String title;
  final Severity severity;
  const CrimeDef(this.title, this.severity);
}

/// The crime menu, grouped by severity. Severity is what the eventual
/// sentence is drawn against (see sentence_pool.dart), so it has to be
/// picked here, at filing time, not guessed later.
const List<CrimeDef> crimeMenu = [
  // Minor
  CrimeDef('Left dishes in the sink overnight', Severity.minor),
  CrimeDef('Ate the last slice without asking', Severity.minor),
  CrimeDef('Finished the milk, put the empty carton back', Severity.minor),
  CrimeDef('Left the fridge door open "just for a sec"', Severity.minor),

  // Medium
  CrimeDef('Took a labeled snack', Severity.medium),
  CrimeDef('"Borrowed" leftovers without asking', Severity.medium),
  CrimeDef('Used the last of something and didn\'t replace it', Severity.medium),
  CrimeDef('Mystery Tupperware, never returned', Severity.medium),

  // Major
  CrimeDef('Grand theft leftovers', Severity.major),
  CrimeDef('Ghosted on a dish-duty swap', Severity.major),
  CrimeDef('Ate a meal that was clearly meal-prepped for the week', Severity.major),
  CrimeDef('Finished someone\'s emotional-support snack', Severity.major),
];

List<CrimeDef> crimesOfSeverity(Severity s) =>
    crimeMenu.where((c) => c.severity == s).toList();
