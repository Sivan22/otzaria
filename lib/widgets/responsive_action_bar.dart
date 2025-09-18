import 'package:flutter/material.dart';

/// רכיב שמציג כפתורי פעולה עם יכולת הסתרה במסכים צרים
/// כשחלק מהכפתורים נסתרים, מוצג כפתור "..." בצד שמאל שפותח תפריט
class ResponsiveActionBar extends StatefulWidget {
  /// רשימת כפתורי הפעולה לפי סדר עדיפות (החשוב ביותר ראשון)
  final List<ActionButtonData> actions;

  /// רוחב מינימלי לכפתור (ברירת מחדל: 48)
  final double buttonMinWidth;

  /// רווח בין כפתורים (ברירת מחדל: 4)
  final double spacing;

  /// מספר מקסימלי של כפתורים להציג לפני מעבר לתפריט "..."
  final int? maxVisibleButtons;

  /// הסדר המקורי של הכפתורים (לתצוגה עקבית)
  final List<ActionButtonData>? originalOrder;

  const ResponsiveActionBar({
    super.key,
    required this.actions,
    this.buttonMinWidth = 48.0,
    this.spacing = 4.0,
    this.maxVisibleButtons,
    this.originalOrder,
  });

  @override
  State<ResponsiveActionBar> createState() => _ResponsiveActionBarState();
}

class _ResponsiveActionBarState extends State<ResponsiveActionBar> {
  @override
  Widget build(BuildContext context) {
    if (widget.actions.isEmpty) {
      return const SizedBox.shrink();
    }

    // אם הוגדר מספר מקסימלי של כפתורים, נשתמש בו
    if (widget.maxVisibleButtons != null) {
      final maxVisible = widget.maxVisibleButtons!;

      // אם כל הכפתורים נכנסים, נציג את כולם
      if (maxVisible >= widget.actions.length) {
        final actionsToShow = widget.originalOrder ?? widget.actions;
        return Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: actionsToShow.reversed
              .map((action) => _buildButton(action))
              .toList(),
        );
      }

      // אם maxVisible הוא 0, נציג רק כפתור "..."
      if (maxVisible <= 0) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr, // כדי שהכפתור "..." יהיה בשמאל
          children: [_buildOverflowButton(widget.actions)],
        );
      }

      // אחרת, נציג חלק מהכפתורים + כפתור "..."
      // נבחר את הכפתורים החשובים ביותר
      final mostImportantActions = widget.actions.take(maxVisible).toList();

      // אם יש סדר מקורי, נסדר את הכפתורים הגלויים לפיו
      List<ActionButtonData> visibleActions;
      List<ActionButtonData> hiddenActions;

      if (widget.originalOrder != null) {
        // נשווה לפי tooltip כדי למצוא את הכפתורים החשובים בסדר המקורי
        final importantTooltips = mostImportantActions
            .map((action) => action.tooltip)
            .where((tooltip) => tooltip != null)
            .toSet();

        // נסנן את הכפתורים הגלויים לפי הסדר המקורי
        visibleActions = widget.originalOrder!
            .where((action) => importantTooltips.contains(action.tooltip))
            .toList();

        // הכפתורים הנסתרים הם כל השאר מהסדר המקורי
        hiddenActions = widget.originalOrder!
            .where((action) => !importantTooltips.contains(action.tooltip))
            .toList();
      } else {
        // אם אין סדר מקורי, נשתמש בסדר העדיפות
        visibleActions = widget.actions.take(maxVisible).toList();
        hiddenActions = widget.actions.skip(maxVisible).toList();
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr, // כדי שהכפתור "..." יהיה בשמאל
        children: [
          // כפתור "..." בצד שמאל
          _buildOverflowButton(hiddenActions),

          // הכפתורים הגלויים (בסדר הפוך כדי להתאים ל-AppBar)
          ...visibleActions.reversed.map((action) => _buildButton(action)),
        ],
      );
    }

    // אם לא הוגדר מספר מקסימלי, נשתמש ב-LayoutBuilder (לעתיד)
    return LayoutBuilder(
      builder: (context, constraints) {
        // חישוב כמה כפתורים יכולים להיכנס ברוחב הזמין
        final availableWidth = constraints.maxWidth;
        final buttonWidth = widget.buttonMinWidth + widget.spacing;

        // בדיקה שהרוחב הזמין תקין
        if (availableWidth <= 0 || buttonWidth <= 0) {
          return const SizedBox.shrink();
        }

        // בדיקה נוספת שהערכים תקינים
        if (!availableWidth.isFinite ||
            !buttonWidth.isFinite ||
            availableWidth.isNaN ||
            buttonWidth.isNaN) {
          return const SizedBox.shrink();
        }

        // אם הרוחב הוא Infinity (כמו ב-AppBar actions), נציג רק כפתור "..."
        if (availableWidth.isInfinite) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [_buildOverflowButton(widget.actions)],
          );
        }

        // קודם נבדוק אם כל הכפתורים נכנסים בלי כפתור "..."
        final maxButtonsWithoutOverflow =
            (availableWidth / buttonWidth).floor();

        // אם כל הכפתורים נכנסים, נציג את כולם בלי כפתור "..."
        if (maxButtonsWithoutOverflow >= widget.actions.length) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children:
                widget.actions.map((action) => _buildButton(action)).toList(),
          );
        }

        // אם לא כל הכפתורים נכנסים, נצטרך כפתור "..."
        final overflowButtonWidth = widget.buttonMinWidth + widget.spacing;
        final availableForButtons = availableWidth - overflowButtonWidth;

        // בדיקה שיש מקום לפחות לכפתור אחד + כפתור "..."
        if (availableForButtons <= 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [_buildOverflowButton(widget.actions)],
          );
        }

        final maxVisibleButtons = (availableForButtons / buttonWidth).floor();

        // אם אין מקום לאף כפתור נוסף מלבד "...", נציג רק אותו
        if (maxVisibleButtons <= 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [_buildOverflowButton(widget.actions)],
          );
        }

        // נציג חלק מהכפתורים + כפתור "..."
        final visibleActions = widget.actions.take(maxVisibleButtons).toList();
        final hiddenActions = widget.actions.skip(maxVisibleButtons).toList();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // כפתור "..." בצד שמאל
            _buildOverflowButton(hiddenActions),

            // הכפתורים הגלויים (החשובים ביותר)
            ...visibleActions.map((action) => _buildButton(action)),
          ],
        );
      },
    );
  }

  Widget _buildButton(ActionButtonData action) {
    return Padding(
      padding: EdgeInsets.only(left: widget.spacing),
      child: action.widget,
    );
  }

  Widget _buildOverflowButton(List<ActionButtonData> hiddenActions) {
    return Padding(
      padding: EdgeInsets.only(left: widget.spacing),
      child: PopupMenuButton<ActionButtonData>(
        icon: const Icon(Icons.more_horiz),
        tooltip: 'עוד פעולות',
        onSelected: (action) {
          action.onPressed?.call();
        },
        itemBuilder: (context) {
          return hiddenActions.map((action) {
            return PopupMenuItem<ActionButtonData>(
              value: action,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (action.icon != null) ...[
                    Icon(action.icon),
                    const SizedBox(width: 8),
                  ],
                  Text(action.tooltip ?? ''),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }
}

/// נתוני כפתור פעולה
class ActionButtonData {
  /// הווידג'ט של הכפתור
  final Widget widget;

  /// האייקון (לשימוש בתפריט הנפתח)
  final IconData? icon;

  /// הטקסט להצגה בתפריט הנפתח
  final String? tooltip;

  /// הפעולה לביצוע כשלוחצים על הכפתור בתפריט
  final VoidCallback? onPressed;

  const ActionButtonData({
    required this.widget,
    this.icon,
    this.tooltip,
    this.onPressed,
  });
}
