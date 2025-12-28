import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.graduationCap, size: 24, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Text(
            'MUSTSTUDY v1.0',
            style: GoogleFonts.getFont(
              'Press Start 2P',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
