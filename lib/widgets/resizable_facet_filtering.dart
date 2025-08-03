import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/search/view/full_text_facet_filtering.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';

/// Widget שמאפשר שינוי גודל של אזור סינון התוצאות
/// ושומר את הגודל בהגדרות המשתמש
class ResizableFacetFiltering extends StatefulWidget {
  final SearchingTab tab;
  final double minWidth;
  final double maxWidth;

  const ResizableFacetFiltering({
    Key? key,
    required this.tab,
    this.minWidth = 150,
    this.maxWidth = 500,
  }) : super(key: key);

  @override
  State<ResizableFacetFiltering> createState() =>
      _ResizableFacetFilteringState();
}

class _ResizableFacetFilteringState extends State<ResizableFacetFiltering> {
  late double _currentWidth;
  bool _isResizing = false;

  @override
  void initState() {
    super.initState();
    // טעינת הרוחב מההגדרות
    final settingsState = context.read<SettingsBloc>().state;
    _currentWidth = settingsState.facetFilteringWidth;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // עדכון הרוחב בהתאם לתנועת העכבר
      // details.delta.dx הוא השינוי ב-x (חיובי = ימינה, שלילי = שמאלה)
      _currentWidth = (_currentWidth - details.delta.dx)
          .clamp(widget.minWidth, widget.maxWidth);
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isResizing = true;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
    // שמירת הרוחב החדש בהגדרות
    context.read<SettingsBloc>().add(UpdateFacetFilteringWidth(_currentWidth));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        // עדכון הרוחב כאשר ההגדרות משתנות מבחוץ
        if (state.facetFilteringWidth != _currentWidth) {
          setState(() {
            _currentWidth = state.facetFilteringWidth;
          });
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // אזור הסינון עצמו
          SizedBox(
            width: _currentWidth,
            child: SearchFacetFiltering(tab: widget.tab),
          ),
          // הידית לשינוי גודל
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: Container(
                width: 8,
                color: _isResizing
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3)
                    : Colors.transparent,
                child: Center(
                  child: Container(
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
