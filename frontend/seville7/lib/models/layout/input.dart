part of 'layout.dart';

/// Native editable input projected onto a Layout-owned surface.
///
/// The owning Layout retains its geometry. Activating the input temporarily
/// replaces that Layout's painted content with a Flutter text editor mapped to
/// the same projected quadrilateral.
class LayoutInputConfig {
  const LayoutInputConfig({
    required this.submission,
    this.hint = const LayoutText.value(''),
    this.text = const LayoutTextConfig(),
    this.backgroundColor = const Color(0xEEFFFFFF),
    this.borderStyle = const GuideStyle(
      color: Color(0xFF3F51B5),
      strokeWidth: 2,
    ),
    this.borderRadius = 0,
    this.horizontalPadding = 12,
  }) : assert(borderRadius >= 0),
       assert(horizontalPadding >= 0);

  final LayoutInputSubmission submission;
  final LayoutText hint;
  final LayoutTextConfig text;
  final Color backgroundColor;
  final GuideStyle borderStyle;
  final double borderRadius;
  final double horizontalPadding;
}

/// Typed effect dispatched when a Layout input is submitted.
sealed class LayoutInputSubmission {
  const LayoutInputSubmission._();

  const factory LayoutInputSubmission.findNodes() =
      FindNodesLayoutInputSubmission;

  const factory LayoutInputSubmission.createVirtualNode() =
      CreateVirtualNodeLayoutInputSubmission;
}

class FindNodesLayoutInputSubmission extends LayoutInputSubmission {
  const FindNodesLayoutInputSubmission() : super._();
}

class CreateVirtualNodeLayoutInputSubmission extends LayoutInputSubmission {
  const CreateVirtualNodeLayoutInputSubmission() : super._();
}
