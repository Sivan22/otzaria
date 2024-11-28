// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $ExternalBooksTable extends ExternalBooks
    with TableInfo<$ExternalBooksTable, ExternalBook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExternalBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pubPlaceMeta =
      const VerificationMeta('pubPlace');
  @override
  late final GeneratedColumn<String> pubPlace = GeneratedColumn<String>(
      'pub_place', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pubDateMeta =
      const VerificationMeta('pubDate');
  @override
  late final GeneratedColumn<String> pubDate = GeneratedColumn<String>(
      'pub_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _topicsMeta = const VerificationMeta('topics');
  @override
  late final GeneratedColumn<String> topics = GeneratedColumn<String>(
      'topics', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _heShortDescMeta =
      const VerificationMeta('heShortDesc');
  @override
  late final GeneratedColumn<String> heShortDesc = GeneratedColumn<String>(
      'he_short_desc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
      'link', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(999));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        author,
        pubPlace,
        pubDate,
        topics,
        heShortDesc,
        link,
        source,
        order
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'external_books';
  @override
  VerificationContext validateIntegrity(Insertable<ExternalBook> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('pub_place')) {
      context.handle(_pubPlaceMeta,
          pubPlace.isAcceptableOrUnknown(data['pub_place']!, _pubPlaceMeta));
    }
    if (data.containsKey('pub_date')) {
      context.handle(_pubDateMeta,
          pubDate.isAcceptableOrUnknown(data['pub_date']!, _pubDateMeta));
    }
    if (data.containsKey('topics')) {
      context.handle(_topicsMeta,
          topics.isAcceptableOrUnknown(data['topics']!, _topicsMeta));
    }
    if (data.containsKey('he_short_desc')) {
      context.handle(
          _heShortDescMeta,
          heShortDesc.isAcceptableOrUnknown(
              data['he_short_desc']!, _heShortDescMeta));
    }
    if (data.containsKey('link')) {
      context.handle(
          _linkMeta, link.isAcceptableOrUnknown(data['link']!, _linkMeta));
    } else if (isInserting) {
      context.missing(_linkMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  ExternalBook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExternalBook(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      pubPlace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pub_place']),
      pubDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pub_date']),
      topics: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topics'])!,
      heShortDesc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}he_short_desc']),
      link: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}link'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
    );
  }

  @override
  $ExternalBooksTable createAlias(String alias) {
    return $ExternalBooksTable(attachedDatabase, alias);
  }
}

class ExternalBook extends DataClass implements Insertable<ExternalBook> {
  final int id;
  final String title;
  final String? author;
  final String? pubPlace;
  final String? pubDate;
  final String topics;
  final String? heShortDesc;
  final String link;
  final String source;
  final int order;
  const ExternalBook(
      {required this.id,
      required this.title,
      this.author,
      this.pubPlace,
      this.pubDate,
      required this.topics,
      this.heShortDesc,
      required this.link,
      required this.source,
      required this.order});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || pubPlace != null) {
      map['pub_place'] = Variable<String>(pubPlace);
    }
    if (!nullToAbsent || pubDate != null) {
      map['pub_date'] = Variable<String>(pubDate);
    }
    map['topics'] = Variable<String>(topics);
    if (!nullToAbsent || heShortDesc != null) {
      map['he_short_desc'] = Variable<String>(heShortDesc);
    }
    map['link'] = Variable<String>(link);
    map['source'] = Variable<String>(source);
    map['order'] = Variable<int>(order);
    return map;
  }

  ExternalBooksCompanion toCompanion(bool nullToAbsent) {
    return ExternalBooksCompanion(
      id: Value(id),
      title: Value(title),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      pubPlace: pubPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(pubPlace),
      pubDate: pubDate == null && nullToAbsent
          ? const Value.absent()
          : Value(pubDate),
      topics: Value(topics),
      heShortDesc: heShortDesc == null && nullToAbsent
          ? const Value.absent()
          : Value(heShortDesc),
      link: Value(link),
      source: Value(source),
      order: Value(order),
    );
  }

  factory ExternalBook.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExternalBook(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      pubPlace: serializer.fromJson<String?>(json['pubPlace']),
      pubDate: serializer.fromJson<String?>(json['pubDate']),
      topics: serializer.fromJson<String>(json['topics']),
      heShortDesc: serializer.fromJson<String?>(json['heShortDesc']),
      link: serializer.fromJson<String>(json['link']),
      source: serializer.fromJson<String>(json['source']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'pubPlace': serializer.toJson<String?>(pubPlace),
      'pubDate': serializer.toJson<String?>(pubDate),
      'topics': serializer.toJson<String>(topics),
      'heShortDesc': serializer.toJson<String?>(heShortDesc),
      'link': serializer.toJson<String>(link),
      'source': serializer.toJson<String>(source),
      'order': serializer.toJson<int>(order),
    };
  }

  ExternalBook copyWith(
          {int? id,
          String? title,
          Value<String?> author = const Value.absent(),
          Value<String?> pubPlace = const Value.absent(),
          Value<String?> pubDate = const Value.absent(),
          String? topics,
          Value<String?> heShortDesc = const Value.absent(),
          String? link,
          String? source,
          int? order}) =>
      ExternalBook(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author.present ? author.value : this.author,
        pubPlace: pubPlace.present ? pubPlace.value : this.pubPlace,
        pubDate: pubDate.present ? pubDate.value : this.pubDate,
        topics: topics ?? this.topics,
        heShortDesc: heShortDesc.present ? heShortDesc.value : this.heShortDesc,
        link: link ?? this.link,
        source: source ?? this.source,
        order: order ?? this.order,
      );
  ExternalBook copyWithCompanion(ExternalBooksCompanion data) {
    return ExternalBook(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      pubPlace: data.pubPlace.present ? data.pubPlace.value : this.pubPlace,
      pubDate: data.pubDate.present ? data.pubDate.value : this.pubDate,
      topics: data.topics.present ? data.topics.value : this.topics,
      heShortDesc:
          data.heShortDesc.present ? data.heShortDesc.value : this.heShortDesc,
      link: data.link.present ? data.link.value : this.link,
      source: data.source.present ? data.source.value : this.source,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExternalBook(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('pubPlace: $pubPlace, ')
          ..write('pubDate: $pubDate, ')
          ..write('topics: $topics, ')
          ..write('heShortDesc: $heShortDesc, ')
          ..write('link: $link, ')
          ..write('source: $source, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, author, pubPlace, pubDate, topics,
      heShortDesc, link, source, order);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExternalBook &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.pubPlace == this.pubPlace &&
          other.pubDate == this.pubDate &&
          other.topics == this.topics &&
          other.heShortDesc == this.heShortDesc &&
          other.link == this.link &&
          other.source == this.source &&
          other.order == this.order);
}

class ExternalBooksCompanion extends UpdateCompanion<ExternalBook> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> pubPlace;
  final Value<String?> pubDate;
  final Value<String> topics;
  final Value<String?> heShortDesc;
  final Value<String> link;
  final Value<String> source;
  final Value<int> order;
  final Value<int> rowid;
  const ExternalBooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.pubPlace = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.topics = const Value.absent(),
    this.heShortDesc = const Value.absent(),
    this.link = const Value.absent(),
    this.source = const Value.absent(),
    this.order = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExternalBooksCompanion.insert({
    required int id,
    required String title,
    this.author = const Value.absent(),
    this.pubPlace = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.topics = const Value.absent(),
    this.heShortDesc = const Value.absent(),
    required String link,
    required String source,
    this.order = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        link = Value(link),
        source = Value(source);
  static Insertable<ExternalBook> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? pubPlace,
    Expression<String>? pubDate,
    Expression<String>? topics,
    Expression<String>? heShortDesc,
    Expression<String>? link,
    Expression<String>? source,
    Expression<int>? order,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (pubPlace != null) 'pub_place': pubPlace,
      if (pubDate != null) 'pub_date': pubDate,
      if (topics != null) 'topics': topics,
      if (heShortDesc != null) 'he_short_desc': heShortDesc,
      if (link != null) 'link': link,
      if (source != null) 'source': source,
      if (order != null) 'order': order,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExternalBooksCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? author,
      Value<String?>? pubPlace,
      Value<String?>? pubDate,
      Value<String>? topics,
      Value<String?>? heShortDesc,
      Value<String>? link,
      Value<String>? source,
      Value<int>? order,
      Value<int>? rowid}) {
    return ExternalBooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      pubPlace: pubPlace ?? this.pubPlace,
      pubDate: pubDate ?? this.pubDate,
      topics: topics ?? this.topics,
      heShortDesc: heShortDesc ?? this.heShortDesc,
      link: link ?? this.link,
      source: source ?? this.source,
      order: order ?? this.order,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (pubPlace.present) {
      map['pub_place'] = Variable<String>(pubPlace.value);
    }
    if (pubDate.present) {
      map['pub_date'] = Variable<String>(pubDate.value);
    }
    if (topics.present) {
      map['topics'] = Variable<String>(topics.value);
    }
    if (heShortDesc.present) {
      map['he_short_desc'] = Variable<String>(heShortDesc.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExternalBooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('pubPlace: $pubPlace, ')
          ..write('pubDate: $pubDate, ')
          ..write('topics: $topics, ')
          ..write('heShortDesc: $heShortDesc, ')
          ..write('link: $link, ')
          ..write('source: $source, ')
          ..write('order: $order, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExternalBooksTable externalBooks = $ExternalBooksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [externalBooks];
}

typedef $$ExternalBooksTableCreateCompanionBuilder = ExternalBooksCompanion
    Function({
  required int id,
  required String title,
  Value<String?> author,
  Value<String?> pubPlace,
  Value<String?> pubDate,
  Value<String> topics,
  Value<String?> heShortDesc,
  required String link,
  required String source,
  Value<int> order,
  Value<int> rowid,
});
typedef $$ExternalBooksTableUpdateCompanionBuilder = ExternalBooksCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<String?> author,
  Value<String?> pubPlace,
  Value<String?> pubDate,
  Value<String> topics,
  Value<String?> heShortDesc,
  Value<String> link,
  Value<String> source,
  Value<int> order,
  Value<int> rowid,
});

class $$ExternalBooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ExternalBooksTable,
    ExternalBook,
    $$ExternalBooksTableFilterComposer,
    $$ExternalBooksTableOrderingComposer,
    $$ExternalBooksTableCreateCompanionBuilder,
    $$ExternalBooksTableUpdateCompanionBuilder> {
  $$ExternalBooksTableTableManager(_$AppDatabase db, $ExternalBooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ExternalBooksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ExternalBooksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<String?> pubPlace = const Value.absent(),
            Value<String?> pubDate = const Value.absent(),
            Value<String> topics = const Value.absent(),
            Value<String?> heShortDesc = const Value.absent(),
            Value<String> link = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExternalBooksCompanion(
            id: id,
            title: title,
            author: author,
            pubPlace: pubPlace,
            pubDate: pubDate,
            topics: topics,
            heShortDesc: heShortDesc,
            link: link,
            source: source,
            order: order,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int id,
            required String title,
            Value<String?> author = const Value.absent(),
            Value<String?> pubPlace = const Value.absent(),
            Value<String?> pubDate = const Value.absent(),
            Value<String> topics = const Value.absent(),
            Value<String?> heShortDesc = const Value.absent(),
            required String link,
            required String source,
            Value<int> order = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExternalBooksCompanion.insert(
            id: id,
            title: title,
            author: author,
            pubPlace: pubPlace,
            pubDate: pubDate,
            topics: topics,
            heShortDesc: heShortDesc,
            link: link,
            source: source,
            order: order,
            rowid: rowid,
          ),
        ));
}

class $$ExternalBooksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ExternalBooksTable> {
  $$ExternalBooksTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get author => $state.composableBuilder(
      column: $state.table.author,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pubPlace => $state.composableBuilder(
      column: $state.table.pubPlace,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pubDate => $state.composableBuilder(
      column: $state.table.pubDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get topics => $state.composableBuilder(
      column: $state.table.topics,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get heShortDesc => $state.composableBuilder(
      column: $state.table.heShortDesc,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get link => $state.composableBuilder(
      column: $state.table.link,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$ExternalBooksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ExternalBooksTable> {
  $$ExternalBooksTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get author => $state.composableBuilder(
      column: $state.table.author,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pubPlace => $state.composableBuilder(
      column: $state.table.pubPlace,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pubDate => $state.composableBuilder(
      column: $state.table.pubDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get topics => $state.composableBuilder(
      column: $state.table.topics,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get heShortDesc => $state.composableBuilder(
      column: $state.table.heShortDesc,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get link => $state.composableBuilder(
      column: $state.table.link,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get source => $state.composableBuilder(
      column: $state.table.source,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExternalBooksTableTableManager get externalBooks =>
      $$ExternalBooksTableTableManager(_db, _db.externalBooks);
}
