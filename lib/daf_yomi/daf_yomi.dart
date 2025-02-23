import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:otzaria/daf_yomi/calendar.dart';

class DafYomi extends StatelessWidget {
  final Function(String tractate, String daf) onDafYomiTap;

  const DafYomi({
    super.key,
    required this.onDafYomiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final Daf dafYomi = getDafYomi(DateTime.now());

        final tractate = dafYomi.getMasechta();
        final dafAmud = dafYomi.getDaf();
        return InkWell(
          onTap: () => onDafYomiTap(
            tractate,
            formatAmud(dafAmud),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      getHebrewDateFormattedAsString(DateTime.now()),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'דף היומי: $tractate ${formatAmud(dafAmud)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
