// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ref.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetRefCollection on Isar {
  IsarCollection<int, Ref> get refs => this.collection();
}

const RefSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: 'Ref',
    idName: 'id',
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: 'ref',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'bookTitle',
        type: IsarType.string,
      ),
      IsarPropertySchema(
        name: 'index',
        type: IsarType.long,
      ),
      IsarPropertySchema(
        name: 'pdfBook',
        type: IsarType.bool,
      ),
      IsarPropertySchema(
        name: 'pdfPath',
        type: IsarType.string,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, Ref>(
    serialize: serializeRef,
    deserialize: deserializeRef,
    deserializeProperty: deserializeRefProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeRef(IsarWriter writer, Ref object) {
  IsarCore.writeString(writer, 1, object.ref);
  IsarCore.writeString(writer, 2, object.bookTitle);
  IsarCore.writeLong(writer, 3, object.index);
  IsarCore.writeBool(writer, 4, object.pdfBook);
  {
    final value = object.pdfPath;
    if (value == null) {
      IsarCore.writeNull(writer, 5);
    } else {
      IsarCore.writeString(writer, 5, value);
    }
  }
  return object.id;
}

@isarProtected
Ref deserializeRef(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final String _ref;
  _ref = IsarCore.readString(reader, 1) ?? '';
  final String _bookTitle;
  _bookTitle = IsarCore.readString(reader, 2) ?? '';
  final int _index;
  _index = IsarCore.readLong(reader, 3);
  final bool _pdfBook;
  _pdfBook = IsarCore.readBool(reader, 4);
  final String? _pdfPath;
  _pdfPath = IsarCore.readString(reader, 5);
  final object = Ref(
    id: _id,
    ref: _ref,
    bookTitle: _bookTitle,
    index: _index,
    pdfBook: _pdfBook,
    pdfPath: _pdfPath,
  );
  return object;
}

@isarProtected
dynamic deserializeRefProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readString(reader, 1) ?? '';
    case 2:
      return IsarCore.readString(reader, 2) ?? '';
    case 3:
      return IsarCore.readLong(reader, 3);
    case 4:
      return IsarCore.readBool(reader, 4);
    case 5:
      return IsarCore.readString(reader, 5);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _RefUpdate {
  bool call({
    required int id,
    String? ref,
    String? bookTitle,
    int? index,
    bool? pdfBook,
    String? pdfPath,
  });
}

class _RefUpdateImpl implements _RefUpdate {
  const _RefUpdateImpl(this.collection);

  final IsarCollection<int, Ref> collection;

  @override
  bool call({
    required int id,
    Object? ref = ignore,
    Object? bookTitle = ignore,
    Object? index = ignore,
    Object? pdfBook = ignore,
    Object? pdfPath = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (ref != ignore) 1: ref as String?,
          if (bookTitle != ignore) 2: bookTitle as String?,
          if (index != ignore) 3: index as int?,
          if (pdfBook != ignore) 4: pdfBook as bool?,
          if (pdfPath != ignore) 5: pdfPath as String?,
        }) >
        0;
  }
}

sealed class _RefUpdateAll {
  int call({
    required List<int> id,
    String? ref,
    String? bookTitle,
    int? index,
    bool? pdfBook,
    String? pdfPath,
  });
}

class _RefUpdateAllImpl implements _RefUpdateAll {
  const _RefUpdateAllImpl(this.collection);

  final IsarCollection<int, Ref> collection;

  @override
  int call({
    required List<int> id,
    Object? ref = ignore,
    Object? bookTitle = ignore,
    Object? index = ignore,
    Object? pdfBook = ignore,
    Object? pdfPath = ignore,
  }) {
    return collection.updateProperties(id, {
      if (ref != ignore) 1: ref as String?,
      if (bookTitle != ignore) 2: bookTitle as String?,
      if (index != ignore) 3: index as int?,
      if (pdfBook != ignore) 4: pdfBook as bool?,
      if (pdfPath != ignore) 5: pdfPath as String?,
    });
  }
}

extension RefUpdate on IsarCollection<int, Ref> {
  _RefUpdate get update => _RefUpdateImpl(this);

  _RefUpdateAll get updateAll => _RefUpdateAllImpl(this);
}

sealed class _RefQueryUpdate {
  int call({
    String? ref,
    String? bookTitle,
    int? index,
    bool? pdfBook,
    String? pdfPath,
  });
}

class _RefQueryUpdateImpl implements _RefQueryUpdate {
  const _RefQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Ref> query;
  final int? limit;

  @override
  int call({
    Object? ref = ignore,
    Object? bookTitle = ignore,
    Object? index = ignore,
    Object? pdfBook = ignore,
    Object? pdfPath = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (ref != ignore) 1: ref as String?,
      if (bookTitle != ignore) 2: bookTitle as String?,
      if (index != ignore) 3: index as int?,
      if (pdfBook != ignore) 4: pdfBook as bool?,
      if (pdfPath != ignore) 5: pdfPath as String?,
    });
  }
}

extension RefQueryUpdate on IsarQuery<Ref> {
  _RefQueryUpdate get updateFirst => _RefQueryUpdateImpl(this, limit: 1);

  _RefQueryUpdate get updateAll => _RefQueryUpdateImpl(this);
}

class _RefQueryBuilderUpdateImpl implements _RefQueryUpdate {
  const _RefQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Ref, Ref, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? ref = ignore,
    Object? bookTitle = ignore,
    Object? index = ignore,
    Object? pdfBook = ignore,
    Object? pdfPath = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (ref != ignore) 1: ref as String?,
        if (bookTitle != ignore) 2: bookTitle as String?,
        if (index != ignore) 3: index as int?,
        if (pdfBook != ignore) 4: pdfBook as bool?,
        if (pdfPath != ignore) 5: pdfPath as String?,
      });
    } finally {
      q.close();
    }
  }
}

extension RefQueryBuilderUpdate on QueryBuilder<Ref, Ref, QOperations> {
  _RefQueryUpdate get updateFirst => _RefQueryBuilderUpdateImpl(this, limit: 1);

  _RefQueryUpdate get updateAll => _RefQueryBuilderUpdateImpl(this);
}

extension RefQueryFilter on QueryBuilder<Ref, Ref, QFilterCondition> {
  QueryBuilder<Ref, Ref, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 1,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 1,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> refIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 1,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleGreaterThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleGreaterThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleLessThan(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleLessThanOrEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleBetween(
    String lower,
    String upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 2,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 2,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 2,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> bookTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 2,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> indexEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> indexGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> indexGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> indexLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> indexLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 3,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> indexBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 3,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfBookEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 4,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathIsNotNull() {
    return QueryBuilder.apply(not(), (query) {
      return query.addFilterCondition(const IsNullCondition(property: 5));
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathGreaterThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathGreaterThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathLessThan(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathLessThanOrEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathBetween(
    String? lower,
    String? upper, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 5,
          lower: lower,
          upper: upper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        StartsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EndsWithCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        ContainsCondition(
          property: 5,
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        MatchesCondition(
          property: 5,
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const EqualCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterFilterCondition> pdfPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const GreaterCondition(
          property: 5,
          value: '',
        ),
      );
    });
  }
}

extension RefQueryObject on QueryBuilder<Ref, Ref, QFilterCondition> {}

extension RefQuerySortBy on QueryBuilder<Ref, Ref, QSortBy> {
  QueryBuilder<Ref, Ref, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByRef({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByRefDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        1,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByBookTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByBookTitleDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        2,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByPdfBook() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByPdfBookDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByPdfPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> sortByPdfPathDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(
        5,
        sort: Sort.desc,
        caseSensitive: caseSensitive,
      );
    });
  }
}

extension RefQuerySortThenBy on QueryBuilder<Ref, Ref, QSortThenBy> {
  QueryBuilder<Ref, Ref, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByRef({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByRefDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByBookTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByBookTitleDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(2, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(3, sort: Sort.desc);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByPdfBook() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByPdfBookDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(4, sort: Sort.desc);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByPdfPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ref, Ref, QAfterSortBy> thenByPdfPathDesc(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(5, sort: Sort.desc, caseSensitive: caseSensitive);
    });
  }
}

extension RefQueryWhereDistinct on QueryBuilder<Ref, Ref, QDistinct> {
  QueryBuilder<Ref, Ref, QAfterDistinct> distinctByRef(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ref, Ref, QAfterDistinct> distinctByBookTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(2, caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Ref, Ref, QAfterDistinct> distinctByIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(3);
    });
  }

  QueryBuilder<Ref, Ref, QAfterDistinct> distinctByPdfBook() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(4);
    });
  }

  QueryBuilder<Ref, Ref, QAfterDistinct> distinctByPdfPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(5, caseSensitive: caseSensitive);
    });
  }
}

extension RefQueryProperty1 on QueryBuilder<Ref, Ref, QProperty> {
  QueryBuilder<Ref, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Ref, String, QAfterProperty> refProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Ref, String, QAfterProperty> bookTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Ref, int, QAfterProperty> indexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Ref, bool, QAfterProperty> pdfBookProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Ref, String?, QAfterProperty> pdfPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension RefQueryProperty2<R> on QueryBuilder<Ref, R, QAfterProperty> {
  QueryBuilder<Ref, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Ref, (R, String), QAfterProperty> refProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Ref, (R, String), QAfterProperty> bookTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Ref, (R, int), QAfterProperty> indexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Ref, (R, bool), QAfterProperty> pdfBookProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Ref, (R, String?), QAfterProperty> pdfPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}

extension RefQueryProperty3<R1, R2>
    on QueryBuilder<Ref, (R1, R2), QAfterProperty> {
  QueryBuilder<Ref, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Ref, (R1, R2, String), QOperations> refProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }

  QueryBuilder<Ref, (R1, R2, String), QOperations> bookTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(2);
    });
  }

  QueryBuilder<Ref, (R1, R2, int), QOperations> indexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(3);
    });
  }

  QueryBuilder<Ref, (R1, R2, bool), QOperations> pdfBookProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(4);
    });
  }

  QueryBuilder<Ref, (R1, R2, String?), QOperations> pdfPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(5);
    });
  }
}
