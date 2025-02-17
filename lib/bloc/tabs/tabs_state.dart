import 'package:equatable/equatable.dart';
import 'package:otzaria/models/tabs/tab.dart';

class TabsState extends Equatable {
  final List<OpenedTab> tabs;
  final int currentTabIndex;

  const TabsState({
    required this.tabs,
    required this.currentTabIndex,
  });

  factory TabsState.initial() {
    return const TabsState(
      tabs: [],
      currentTabIndex: 0,
    );
  }

  TabsState copyWith({
    List<OpenedTab>? tabs,
    int? currentTabIndex,
  }) {
    return TabsState(
      tabs: tabs ?? this.tabs,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
    );
  }

  bool get hasOpenTabs => tabs.isNotEmpty;
  OpenedTab? get currentTab => hasOpenTabs ? tabs[currentTabIndex] : null;

  @override
  List<Object?> get props => [tabs, currentTabIndex];
}
