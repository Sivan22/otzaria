import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/utils/font_utils.dart';

class QuickFontSelector extends StatelessWidget {
  final String? currentFont;
  final Function(String) onFontChanged;

  const QuickFontSelector({
    Key? key,
    this.currentFont,
    required this.onFontChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return PopupMenuButton<String>(
          icon: const Icon(Icons.font_download_outlined),
          tooltip: 'שינוי גופן',
          onSelected: onFontChanged,
          itemBuilder: (context) {
            final builtInFonts = FontUtils.getBuiltInFonts();
            final items = <PopupMenuEntry<String>>[];

            // גופנים מובנים
            for (final entry in builtInFonts.entries) {
              items.add(
                PopupMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      if (currentFont == entry.key)
                        const Icon(Icons.check, size: 16)
                      else
                        const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: entry.key,
                            fontWeight: currentFont == entry.key 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // מפריד אם יש גופנים אישיים
            if (state.customFonts.isNotEmpty) {
              items.add(const PopupMenuDivider());
              items.add(
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'גופנים אישיים:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              );

              // גופנים אישיים
              for (final font in state.customFonts) {
                items.add(
                  PopupMenuItem<String>(
                    value: font.id,
                    child: Row(
                      children: [
                        if (currentFont == font.id)
                          const Icon(Icons.check, size: 16)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            font.displayName,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: font.id,
                              fontWeight: currentFont == font.id 
                                  ? FontWeight.bold 
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }

            return items;
          },
        );
      },
    );
  }
}