import 'package:flutter/material.dart';

/// רכיב שמציג כפתורי פעולה עם יכולת הסתרה במסכים צרים
/// כשחלק מהכפתורים נסתרים, מוצג כפתור "..." שפותח תפריט
class ResponsiveActionBar extends StatefulWidget {
  /// רשימת כפתורי הפעולה לפי סדר עדיפות (החשוב ביותר ראשון)
  final List<ActionButtonData> actions;

  /// הסדר המקורי של הכפתורים (לתצוגה עקבית). זו הרשימה שקובעת את הסדר החזותי.
  final List<ActionButtonData> originalOrder;

  /// מספר מקסימלי של כפתורים להציג לפני מעבר לתפריט "..."
  final int maxVisibleButtons;

  /// האם כפתור "..." יהיה בצד ימין (ברירת מחדל: false - שמאל)
  final bool overflowOnRight;

  const ResponsiveActionBar({
    super.key,
    required this.actions,
    required this.originalOrder,
    required this.maxVisibleButtons,
    this.overflowOnRight = false,
  });

  @override
  State<ResponsiveActionBar> createState() => _ResponsiveActionBarState();
}

class _ResponsiveActionBarState extends State<ResponsiveActionBar> {
  @override
  Widget build(BuildContext context) {
    if (widget.originalOrder.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalButtons = widget.originalOrder.length;
    int effectiveMaxVisible = widget.maxVisibleButtons;

    // אם צריך להסתיר רק כפתור אחד, אין טעם להציג תפריט שתופס מקום בעצמו.
    // עדיף פשוט להציג את כל הכפתורים.
    if (totalButtons - widget.maxVisibleButtons == 1) {
      effectiveMaxVisible = totalButtons;
    }

    List<ActionButtonData> visibleActions;
    List<ActionButtonData> hiddenActions;

    // אם יש מקום לכל הכפתורים, נציג את כולם וללא תפריט "..."
    if (effectiveMaxVisible >= totalButtons) {
      visibleActions = List.from(widget.originalOrder);
      hiddenActions = [];
    } else {
      final numToHide = totalButtons - effectiveMaxVisible;

      // ניקח את הכפתורים הפחות חשובים מרשימת העדיפויות
      final Set<ActionButtonData> actionsToHide =
          widget.actions.reversed.take(numToHide).toSet();

      visibleActions = [];
      hiddenActions = [];

      // נחלק את הכפתורים (לפי הסדר המקורי!) לגלויים ונסתרים
      for (final action in widget.originalOrder) {
        if (actionsToHide.contains(action)) {
          hiddenActions.add(action);
        } else {
          visibleActions.add(action);
        }
      }
    }

    final visibleWidgets =
        visibleActions.map((action) => action.widget).toList();
    final List<Widget> children = [];

    if (widget.overflowOnRight) {
      // מסך הספרייה: תפריט בצד ימין. הסדר החזותי R->L דורש היפוך הרשימה.
      children.addAll(visibleWidgets.reversed);
      if (hiddenActions.isNotEmpty) {
        children.add(_buildOverflowButton(hiddenActions));
      }
    } else {
      // מסך הספר: תפריט בצד שמאל. הסדר הטבעי של הרשימה מתאים.
      if (hiddenActions.isNotEmpty) {
        children.add(_buildOverflowButton(hiddenActions));
      }
      children.addAll(visibleWidgets);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: children,
    );
  }

  Widget _buildOverflowButton(List<ActionButtonData> hiddenActions) {
    // נציג את הכפתורים הנסתרים בתפריט בסדר המקורי שלהם
    final orderedHiddenActions = widget.originalOrder
        .where((action) => hiddenActions.contains(action))
        .toList();

    return PopupMenuButton<ActionButtonData>(
      icon: const Icon(Icons.more_horiz),
      tooltip: 'עוד פעולות',
      // הוספת offset כדי למקם את התפריט מתחת לכפתור
      offset: const Offset(0, 40.0),
      onSelected: (action) {
        action.onPressed?.call();
      },
      itemBuilder: (context) {
        return orderedHiddenActions.map((action) {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionButtonData &&
          runtimeType == other.runtimeType &&
          tooltip == other.tooltip;

  @override
  int get hashCode => tooltip.hashCode;
}
