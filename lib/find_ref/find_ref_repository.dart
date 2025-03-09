import 'package:otzaria/data/data_providers/isar_data_provider.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/isar_collections/ref.dart';

class FindRefRepository {
  final DataRepository dataRepository;
  final IsarDataProvider _isarDataProvider =
      IsarDataProvider.instance; // Direct access to IsarDataProvider

  FindRefRepository({required this.dataRepository});

  Future<List<Ref>> findRefs(String ref) async {
    return _isarDataProvider.findRefsByRelevance(
      // Use _isarDataProvider directly
      ref,
    );
  }

  Future<int> getNumberOfBooksWithRefs() async {
    return _isarDataProvider
        .getNumberOfBooksWithRefs(); // Use _isarDataProvider directly
  }
}
