import 'package:drawing_core/drawing_core.dart';
import 'package:flutter/material.dart';

/// How a cover title is applied to its material.
enum CoverTitleTreatment {
  debossed,
  foilGold,
  foilSilver,
  foilCopper,
  inkOnLabel,
}

/// Picks the title treatment for [cover]: foil on leathers and slate, ink on
/// the kraft label plate, debossed everywhere else.
CoverTitleTreatment coverTitleTreatment(Cover cover) {
  switch (cover.id) {
    case 'leather_oxblood':
      return CoverTitleTreatment.foilGold;
    case 'leather_navy':
    case 'linen_slate':
      return CoverTitleTreatment.foilSilver;
    case 'leather_cognac':
      return CoverTitleTreatment.foilCopper;
  }
  return cover.material == CoverMaterial.kraft
      ? CoverTitleTreatment.inkOnLabel
      : CoverTitleTreatment.debossed;
}

/// The typed title for a material cover, centred in [zone].
///
/// Debossed (glyph darker than the cover with an inner shadow above and a
/// highlight below) or foil-stamped (metallic gradient with a diagonal glint
/// over a dark contact shadow). [scale] is the cover width over 240 dp.
class CoverTitleOverlay extends StatelessWidget {
  const CoverTitleOverlay({
    super.key,
    required this.cover,
    required this.title,
    required this.zone,
    this.scale = 1,
  });

  final Cover cover;
  final String title;
  final Rect zone;
  final double scale;

  static const _gold = [
    Color(0xFFF1D58A),
    Color(0xFFD9AD55),
    Color(0xFFFFF6D0),
    Color(0xFFD2A44C),
    Color(0xFFE9C874),
  ];
  static const _silver = [
    Color(0xFFE4E8EE),
    Color(0xFFB7BFCA),
    Color(0xFFFFFFFF),
    Color(0xFFADB6C2),
    Color(0xFFDCE1E8),
  ];
  static const _copper = [
    Color(0xFFF7CDA4),
    Color(0xFFEBAC7A),
    Color(0xFFFFF0DE),
    Color(0xFFE7A271),
    Color(0xFFF3C196),
  ];
  // Narrow bright band = one diagonal specular glint.
  static const _stops = [0.0, 0.40, 0.47, 0.54, 1.0];

  /// Cover colour with lightness scaled down (0.75x, deeper if needed) until
  /// it reaches 3:1 luminance contrast against the cover.
  static Color debossInk(Color base) {
    final hsl = HSLColor.fromColor(base);
    var f = 0.75;
    Color ink = hsl.withLightness(hsl.lightness * f).toColor();
    while (f > 0.2 && _contrast(base, ink) < 3) {
      f -= 0.05;
      ink = hsl.withLightness(hsl.lightness * f).toColor();
    }
    return ink;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance() + 0.05;
    final lb = b.computeLuminance() + 0.05;
    return la > lb ? la / lb : lb / la;
  }

  @override
  Widget build(BuildContext context) {
    final treatment = coverTitleTreatment(cover);
    final base = Color(cover.primaryColor);
    final fontSize = zone.height * 0.5;
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: scale < 0.7 ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: fontSize * 0.07,
              height: 1.15,
            ) ??
        TextStyle(fontSize: fontSize);
    final lip = 0.75 * scale.clamp(0.7, 4.0);

    Widget text(TextStyle s) => Text(
          title,
          style: s,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
    Widget shifted(double dy, Color color) => Transform.translate(
        offset: Offset(0, dy), child: text(style.copyWith(color: color)));

    final Widget content;
    switch (treatment) {
      case CoverTitleTreatment.foilGold:
      case CoverTitleTreatment.foilSilver:
      case CoverTitleTreatment.foilCopper:
        final colors = switch (treatment) {
          CoverTitleTreatment.foilGold => _gold,
          CoverTitleTreatment.foilCopper => _copper,
          _ => _silver,
        };
        content = Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(lip * 0.6, lip * 1.5),
              child: text(style.copyWith(color: const Color(0x99000000))),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
                stops: _stops,
              ).createShader(r),
              child: text(style.copyWith(color: Colors.white)),
            ),
          ],
        );
      case CoverTitleTreatment.inkOnLabel:
        content =
            text(style.copyWith(color: const Color(CoverFamily.labelInkColor)));
      case CoverTitleTreatment.debossed:
        content = Stack(
          alignment: Alignment.center,
          children: [
            shifted(lip, const Color(0x40FFFFFF)), // highlight below
            shifted(-lip, const Color(0x59000000)), // inner shadow above
            text(style.copyWith(color: debossInk(base))),
          ],
        );
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
