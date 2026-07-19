enum GraphTraverseType {
  partOf('part_of'),
  family('family');

  const GraphTraverseType(this.queryValue);

  final String queryValue;
}
