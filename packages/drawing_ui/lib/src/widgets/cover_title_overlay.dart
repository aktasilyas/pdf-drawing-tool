import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';

/// How a cover title is applied to its material.
enum CoverTitleTreatment { debossed, foilGold, foilSilver, inkOnLabel }

/// Picks the title treatment for [cover]: foil on dark leathers, ink on the
/// kraft label plate, debossed everywhere else.
CoverTitleTreatment coverTitleTreatment(Cover cover) {
  switch (cover.id) {
    case 'leather_oxblood':
      return CoverTitleTreatment.foilGold;
    case 'leather_navy':
      return CoverTitleTreatment.foilSilver;
  }
  return cover.material == CoverMaterial.kraft
      ? CoverTitleTreatment.inkOnLabel
      : CoverTitleTreatment.debossed;
}

/// The typed title for a material cover, centred in [zone].
///
/// Debossed (pressed into the material: tinted darker/lighter with a highlight
/// on the lower lip) or foil-stamped (metallic gradient with a glint over a
/// dark contact shadow). No box behind it.
class CoverTitleOverlay extends StatelessWidget {
  const CoverTitleOverlay({
    super.key,
    required this.cover,
    required this.title,
    required this.zone,
  });

  final Cover cover;
  final String title;
  final Rect zone;

  static const _gold = [
    Color(0xFFF6DE98),
    Color(0xFFC79A45),
    Color(0xFFFFF3C4),
    Color(0xFFB08536),
    Color(0xFFE6C36F),
  ];
  static const _silver = [
    Color(0xFFF2F4F7),
    Color(0xFFA9B1BC),
    Color(0xFFFFFFFF),
    Color(0xFF8E97A4),
    Color(0xFFDDE2E8),
  ];

  @override
  Widget build(BuildContext context) {
    final treatment = coverTitleTreatment(cover);
    final base = Color(cover.primaryColor);
    final fontSize = zone.height * 0.5;
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: fontSize * 0.07,
              height: 1.15,
            ) ??
        TextStyle(fontSize: fontSize);

    Widget text(TextStyle s) => Text(
          title,
          style: s,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );

    final Widget content;
    switch (treatment) {
      case CoverTitleTreatment.foilGold:
      case CoverTitleTreatment.foilSilver:
        final colors =
            treatment == CoverTitleTreatment.foilGold ? _gold : _silver;
        final lip = zone.height * 0.02;
        content = Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(lip * 0.6, lip * 1.4),
              child: text(style.copyWith(color: const Color(0x8C000000))),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
                stops: const [0, 0.3, 0.45, 0.7, 1],
              ).createShader(r),
              child: text(style.copyWith(color: Colors.white)),
            ),
          ],
        );
      case CoverTitleTreatment.inkOnLabel:
        content =
            text(style.copyWith(color: const Color(CoverFamily.labelInkColor)));
      case CoverTitleTreatment.debossed:
        final light = base.computeLuminance() < 0.2;
        final ink = Color.lerp(
            base, light ? Colors.white : Colors.black, light ? 0.5 : 0.42)!;
        final lip = (zone.height * 0.018).clamp(0.5, 2.0);
        content = text(style.copyWith(color: ink, shadows: [
          Shadow(
              color: (light ? Colors.black : Colors.white)
                  .withValues(alpha: light ? 0.4 : 0.38),
              offset: Offset(0, lip)),
        ]));
    }

    return Positioned.fromRect(
      rect: zone,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: zone.height * 0.12, vertical: zone.height * 0.08),
        child: LayoutBuilder(
          builder: (context, inner) => FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(width: inner.maxWidth, child: content),
          ),
        ),
      ),
    );
  }
}
