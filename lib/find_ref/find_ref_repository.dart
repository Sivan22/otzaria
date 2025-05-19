import 'package:otzaria/data/data_providers/tantivy_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'package:search_engine/search_engine.dart';

class FindRefRepository {
  final DataRepository dataRepository;

  FindRefRepository({required this.dataRepository});

  Future<List<ReferenceSearchResult>> findRefs(String ref) async {
    return await TantivyDataProvider.instance
        .searchRefs(replaceParaphrases(removeSectionNames(ref)), 100, false);
  }
}
