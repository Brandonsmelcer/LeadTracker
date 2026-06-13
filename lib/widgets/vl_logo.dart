import 'package:flutter/material.dart';

const kAppLogoAsset = 'assets/images/logo.png';

class VlLogo extends StatelessWidget {
  final double height;
  final BoxFit fit;
  final Alignment alignment;

  const VlLogo({
    super.key,
    this.height = 32,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      kAppLogoAsset,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.high,
    );
  }
}

class VlBrandingRow extends StatelessWidget {
  final double logoHeight;

  const VlBrandingRow({super.key, this.logoHeight = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        VlLogo(height: logoHeight),
        const SizedBox(width: 12),
        Container(
          height: logoHeight * 0.7,
          width: 1,
          color: Colors.white24,
        ),
        const SizedBox(width: 12),
        const Text(
          'VISION TO LEGACY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
