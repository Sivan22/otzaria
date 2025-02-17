import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:otzaria/models/library.dart';

class RefIndexingRepository {
  final IsarDataProvider dataProvider;

  RefIndexingRepository({required this.dataProvider});

  Future<void> createRefsFromLibrary(Library library, int startIndex) async {
    await dataProvider.createRefsFromLibrary(library, startIndex);
  }
}
