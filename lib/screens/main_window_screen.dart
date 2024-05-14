import 'package:flutter/material.dart';
import 'package:flutter_settings_screen_ex/flutter_settings_screen_ex.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/screens/favoriets.dart';
import 'package:otzaria/screens/reading_screen.dart';

//imports from otzaria
import 'package:otzaria/screens/library_browser.dart';
import 'package:otzaria/screens/settings_screen.dart';
import 'package:otzaria/widgets/keyboard_shortcuts.dart';
import 'package:provider/provider.dart';

class MainWindowScreen extends StatefulWidget {
  const MainWindowScreen({Key? key}) : super(key: key);
  @override
  MainWindowScreenState createState() => MainWindowScreenState();
}

class MainWindowScreenState extends State<MainWindowScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  ValueNotifier selectedIndex = ValueNotifier(0);
  final bookSearchfocusNode = FocusNode();
  final FocusScopeNode mainFocusScopeNode = FocusScopeNode();
  PageController? pageController;
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    if (Settings.getValue('key-font-size') == null) {
      Settings.setValue('key-font-size', 25.0);
    }
    if (Settings.getValue('key-font-family') == null) {
      Settings.setValue('key-font-family', 'FrankRuhlCLM');
    }

    final currentView =
        Provider.of<AppModel>(context, listen: false).currentView;
    pageController =
        PageController(initialPage: currentView.value.index, keepPage: true);

    currentView.addListener(() {
      pageController!.animateToPage(
          //show the requested screen, unless it is the search screen, in which case show the reading screen
          currentView.value == Screens.search
              ? Screens.reading.index
              : currentView.value.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear);
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      Provider.of<AppModel>(context, listen: false).saveTabsToDisk();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: KeyboardShortcuts(
        child: Consumer<AppModel>(
          builder: (context, appModel, child) => Scaffold(
            body: OrientationBuilder(builder: (context, orientation) {
              if (orientation == Orientation.landscape) {
                return buildHorizontalLayout(appModel);
              } else {
                return Column(children: [
                  Expanded(
                    child: PageView(
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      controller: pageController,
                      children: const <Widget>[
                        LibraryBrowser(),
                        ReadingScreen(),
                        SizedBox.shrink(),
                        FavouritesScreen(),
                        MySettingsScreen(),
                      ],
                    ),
                  ),
                  buildNavigationBottomBar(),
                ]);
              }
            }),
          ),
        ),
      ),
    );
  }

  Widget buildHorizontalLayout(AppModel appModel) {
    return Row(children: [
      buildNavigationSideBar(appModel),
      //mainWindow
      Expanded(
        child: OrientationBuilder(builder: (context, orientation) {
          return PageView(
            scrollDirection: orientation == Orientation.landscape
                ? Axis.vertical
                : Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            children: const <Widget>[
              LibraryBrowser(),
              ReadingScreen(),
              SizedBox.shrink(),
              FavouritesScreen(),
              MySettingsScreen(),
            ],
          );
        }),
      ),
    ]);
  }

  Widget buildLibraryBrowser(AppModel appModel) {
    return const Expanded(
      child: LibraryBrowser(),
    );
  }

  Widget buildSettingsScreen() {
    return const Expanded(
      child: MySettingsScreen(),
    );
  }

  SizedBox buildNavigationSideBar(AppModel appModel) {
    return SizedBox.fromSize(
      size: const Size.fromWidth(80),
      child: NavigationRail(
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.library_books),
              label: Text('ספרייה'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.menu_book),
              label: Text('עיון'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.search),
              label: Text('חיפוש'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.star),
              label: Text('מועדפים'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings),
              label: Text('הגדרות'),
            ),
          ],
          selectedIndex: appModel.currentView.value.index,
          onDestinationSelected: (int index) {
            appModel.currentView.value = Screens.values[index];
            pageController = PageController(initialPage: index, keepPage: true);
            switch (index) {
              case 2:
                appModel.openNewSearchTab();
            }
            setState(() {});
          }),
    );
  }

  Widget buildNavigationBottomBar() {
    return Consumer<AppModel>(
      builder: (context, appModel, child) => NavigationBar(
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.library_books),
              label: 'ספרייה',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book),
              label: 'עיון',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: 'חיפוש',
            ),
            NavigationDestination(
              icon: Icon(Icons.star),
              label: 'מועדפים',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'הגדרות',
            ),
          ],
          selectedIndex: appModel.currentView.value.index,
          onDestinationSelected: (int index) {
            setState(() {
              appModel.currentView.value = Screens.values[index];
              switch (index) {
                case 2:
                  appModel.openNewSearchTab();
              }
            });
          }),
    );
  }
}
