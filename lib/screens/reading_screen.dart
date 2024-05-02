import 'dart:math';
import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:otzaria/screens/full_text_search_screen.dart';
import 'package:otzaria/screens/pdf_book_screen.dart';
import 'package:otzaria/screens/text_book_screen.dart';
import 'package:provider/provider.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({Key? key}) : super(key: key);

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AppModel>(
      builder: (context, appModel, child) {
        if (appModel.tabs.isEmpty) {
          return const Center(child: Text('לא נבחרו ספרים'));
        }
        return Builder(
          builder: (context) {
            final controller = TabController(
                length: appModel.tabs.length,
                vsync: this,
                initialIndex:
                    min(appModel.currentTab, appModel.tabs.length - 1));
            controller.addListener(() {
              appModel.currentTab = controller.index;
            });
            return Scaffold(
              appBar: buildTabBar(appModel, controller),
              body: buildTabBarView(appModel, controller),
            );
          },
        );
      },
    );
  }

  Widget buildTabBarView(AppModel appModel, TabController? controller) {
    final tabs = appModel.tabs;
    return TabBarView(
        controller: controller,
        children: tabs.map((tab) {
          if (tab is PdfBookTab) {
            return PdfBookViewr(
              key: PageStorageKey(tab),
              tab: tab,
              controller: tab.pdfViewerController,
            );
          } else if (tab is TextBookTab) {
            return TextBookViewer(
              tab: tab,
              openBookCallback: appModel.addTab,
              data: tab.text,
            );
          } else if (tab is SearchingTab) {
            return TextFileSearchScreen(
              openBookCallback: appModel.addTab,
              searcher: tab.searcher,
            );
          }
          return const SizedBox.shrink();
        }).toList());
  }
}

TabBar buildTabBar(AppModel appModel, TabController? controller) {
  return TabBar(
    controller: controller,
    isScrollable: true,
    tabAlignment: TabAlignment.center,
    tabs: appModel.tabs
        .map((tab) => Listener(
              // close tab on middle mouse button click
              onPointerDown: (PointerDownEvent event) {
                if (event.buttons == 4) {
                  appModel.closeTab(tab);
                }
              },
              child: Tab(
                child: Row(children: [
                  Text(
                    tab is SearchingTab
                        ? '${tab.title}:  ${tab.searcher.queryController.text}'
                        : tab.title,
                  ),
                  IconButton(
                      onPressed: () {
                        appModel.closeTab(tab);
                      },
                      icon: const Icon(Icons.close, size: 10))
                ]),
              ),
            ))
        .toList(),
  );
}
