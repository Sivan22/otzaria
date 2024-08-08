import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:provider/provider.dart';
import 'package:otzaria/utils/calendar.dart';

class DafYomi extends StatelessWidget {
  const DafYomi({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) {
        return Container(
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
                    'דף היומי: ${getDafYomi(DateTime.now())}',
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
        );
      },
    );
  }
}
