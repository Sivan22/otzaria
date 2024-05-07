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
    with TickerProviderStateMixin {
  Widget buildTabBarView(AppModel appModel, TabController? controller) {
    return TabBarView(
        controller: controller,
        children: appModel.tabs.map((tab) {
          if (tab is PdfBookTab) {
            return PdfBookViewr(
              key: PageStorageKey(tab),
              tab: tab,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) {
        if (appModel.tabs.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: Text('לא נבחרו ספרים')),
              ),
              // a button to open the library browser
              Center(
                child: ElevatedButton(
                  onPressed: (() => appModel.currentView.value = 0),
                  child: const Text('עיון בספריה'),
                ),
              ),
            ],
          );
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
            try {
              return Scaffold(
                appBar: buildTabBar(appModel, controller),
                body: SizedBox.fromSize(
                    size: MediaQuery.of(context).size,
                    child: buildTabBarView(appModel, controller)),
              );
            } catch (e) {
              return Text(e.toString());
            }
          },
        );
      },
    );
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
