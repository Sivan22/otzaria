import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:otzaria/library/models/library.dart';

class RefIndexingRepository {
  final IsarDataProvider dataProvider;

  RefIndexingRepository({required this.dataProvider, library});

  Future<void> createRefsFromLibrary(Library library, int startIndex) async {
    await dataProvider.createRefsFromLibrary(library, startIndex);
  }
}
