enum StaveBackground {
  paper(label: 'Current color'),
  white(label: 'Pure white');

  const StaveBackground({required this.label});

  final String label;
}
