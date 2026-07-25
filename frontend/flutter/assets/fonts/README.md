# Interface fonts

Seville bundles **Alegreya Sans SC** as its interface family. The Regular,
Medium, Bold, and Black files come from the official
[`google/fonts`](https://github.com/google/fonts/tree/main/ofl/alegreyasanssc)
repository and are distributed under the SIL Open Font License 1.1 included in
`alegreya_sans_sc/OFL.txt`.

The files are registered in `pubspec.yaml`. `SevilleTypography.ensureLoaded()`
also loads the family before `runApp`, while raw Flame `TextPainter` styles use
`SevilleTypography.fontFamily` explicitly because canvas text does not inherit
the Flutter Material theme.
