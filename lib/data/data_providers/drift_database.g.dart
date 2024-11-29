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

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _shortDescriptionMeta =
      const VerificationMeta('shortDescription');
  @override
  late final GeneratedColumn<String> shortDescription = GeneratedColumn<String>(
      'short_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(999));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, parentId, description, shortDescription, order];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('short_description')) {
      context.handle(
          _shortDescriptionMeta,
          shortDescription.isAcceptableOrUnknown(
              data['short_description']!, _shortDescriptionMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}parent_id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      shortDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}short_description']),
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String title;
  final int? parentId;
  final String? description;
  final String? shortDescription;
  final int order;
  const Category(
      {required this.id,
      required this.title,
      this.parentId,
      this.description,
      this.shortDescription,
      required this.order});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || shortDescription != null) {
      map['short_description'] = Variable<String>(shortDescription);
    }
    map['order'] = Variable<int>(order);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      title: Value(title),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      shortDescription: shortDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(shortDescription),
      order: Value(order),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      description: serializer.fromJson<String?>(json['description']),
      shortDescription: serializer.fromJson<String?>(json['shortDescription']),
      order: serializer.fromJson<int>(json['order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'parentId': serializer.toJson<int?>(parentId),
      'description': serializer.toJson<String?>(description),
      'shortDescription': serializer.toJson<String?>(shortDescription),
      'order': serializer.toJson<int>(order),
    };
  }

  Category copyWith(
          {int? id,
          String? title,
          Value<int?> parentId = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> shortDescription = const Value.absent(),
          int? order}) =>
      Category(
        id: id ?? this.id,
        title: title ?? this.title,
        parentId: parentId.present ? parentId.value : this.parentId,
        description: description.present ? description.value : this.description,
        shortDescription: shortDescription.present
            ? shortDescription.value
            : this.shortDescription,
        order: order ?? this.order,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      description:
          data.description.present ? data.description.value : this.description,
      shortDescription: data.shortDescription.present
          ? data.shortDescription.value
          : this.shortDescription,
      order: data.order.present ? data.order.value : this.order,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('parentId: $parentId, ')
          ..write('description: $description, ')
          ..write('shortDescription: $shortDescription, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, parentId, description, shortDescription, order);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.title == this.title &&
          other.parentId == this.parentId &&
          other.description == this.description &&
          other.shortDescription == this.shortDescription &&
          other.order == this.order);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> title;
  final Value<int?> parentId;
  final Value<String?> description;
  final Value<String?> shortDescription;
  final Value<int> order;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.parentId = const Value.absent(),
    this.description = const Value.absent(),
    this.shortDescription = const Value.absent(),
    this.order = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.parentId = const Value.absent(),
    this.description = const Value.absent(),
    this.shortDescription = const Value.absent(),
    this.order = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? parentId,
    Expression<String>? description,
    Expression<String>? shortDescription,
    Expression<int>? order,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (parentId != null) 'parent_id': parentId,
      if (description != null) 'description': description,
      if (shortDescription != null) 'short_description': shortDescription,
      if (order != null) 'order': order,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<int?>? parentId,
      Value<String?>? description,
      Value<String?>? shortDescription,
      Value<int>? order}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      parentId: parentId ?? this.parentId,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      order: order ?? this.order,
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
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (shortDescription.present) {
      map['short_description'] = Variable<String>(shortDescription.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('parentId: $parentId, ')
          ..write('description: $description, ')
          ..write('shortDescription: $shortDescription, ')
          ..write('order: $order')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
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
  static const VerificationMeta _heShortDescMeta =
      const VerificationMeta('heShortDesc');
  @override
  late final GeneratedColumn<String> heShortDesc = GeneratedColumn<String>(
      'he_short_desc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pubDateMeta =
      const VerificationMeta('pubDate');
  @override
  late final GeneratedColumn<String> pubDate = GeneratedColumn<String>(
      'pub_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pubPlaceMeta =
      const VerificationMeta('pubPlace');
  @override
  late final GeneratedColumn<String> pubPlace = GeneratedColumn<String>(
      'pub_place', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _topicsMeta = const VerificationMeta('topics');
  @override
  late final GeneratedColumn<String> topics = GeneratedColumn<String>(
      'topics', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(999));
  static const VerificationMeta _extraTitlesMeta =
      const VerificationMeta('extraTitles');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
      extraTitles = GeneratedColumn<String>('extra_titles', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<String>?>($BooksTable.$converterextraTitlesn);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>?, String>
      metadata = GeneratedColumn<String>('metadata', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<Map<String, dynamic>?>(
              $BooksTable.$convertermetadatan);
  static const VerificationMeta _lastModifiedMeta =
      const VerificationMeta('lastModified');
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
      'last_modified', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdMeta =
      const VerificationMeta('created');
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
      'created', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        author,
        heShortDesc,
        pubDate,
        pubPlace,
        topics,
        order,
        extraTitles,
        path,
        categoryId,
        metadata,
        lastModified,
        created,
        type
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(Insertable<Book> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
    if (data.containsKey('he_short_desc')) {
      context.handle(
          _heShortDescMeta,
          heShortDesc.isAcceptableOrUnknown(
              data['he_short_desc']!, _heShortDescMeta));
    }
    if (data.containsKey('pub_date')) {
      context.handle(_pubDateMeta,
          pubDate.isAcceptableOrUnknown(data['pub_date']!, _pubDateMeta));
    }
    if (data.containsKey('pub_place')) {
      context.handle(_pubPlaceMeta,
          pubPlace.isAcceptableOrUnknown(data['pub_place']!, _pubPlaceMeta));
    }
    if (data.containsKey('topics')) {
      context.handle(_topicsMeta,
          topics.isAcceptableOrUnknown(data['topics']!, _topicsMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    }
    context.handle(_extraTitlesMeta, const VerificationResult.success());
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    context.handle(_metadataMeta, const VerificationResult.success());
    if (data.containsKey('last_modified')) {
      context.handle(
          _lastModifiedMeta,
          lastModified.isAcceptableOrUnknown(
              data['last_modified']!, _lastModifiedMeta));
    } else if (isInserting) {
      context.missing(_lastModifiedMeta);
    }
    if (data.containsKey('created')) {
      context.handle(_createdMeta,
          created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      heShortDesc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}he_short_desc']),
      pubDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pub_date']),
      pubPlace: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pub_place']),
      topics: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}topics'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      extraTitles: $BooksTable.$converterextraTitlesn.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extra_titles'])),
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      metadata: $BooksTable.$convertermetadatan.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])),
      lastModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified'])!,
      created: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterextraTitles =
      const StringListConverter();
  static TypeConverter<List<String>?, String?> $converterextraTitlesn =
      NullAwareTypeConverter.wrap($converterextraTitles);
  static TypeConverter<Map<String, dynamic>, String> $convertermetadata =
      const JsonTypeConverter();
  static TypeConverter<Map<String, dynamic>?, String?> $convertermetadatan =
      NullAwareTypeConverter.wrap($convertermetadata);
}

class Book extends DataClass implements Insertable<Book> {
  final int id;
  final String title;
  final String? author;
  final String? heShortDesc;
  final String? pubDate;
  final String? pubPlace;
  final String topics;
  final int order;
  final List<String>? extraTitles;
  final String? path;
  final int categoryId;
  final Map<String, dynamic>? metadata;
  final DateTime lastModified;
  final DateTime created;
  final String type;
  const Book(
      {required this.id,
      required this.title,
      this.author,
      this.heShortDesc,
      this.pubDate,
      this.pubPlace,
      required this.topics,
      required this.order,
      this.extraTitles,
      this.path,
      required this.categoryId,
      this.metadata,
      required this.lastModified,
      required this.created,
      required this.type});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || heShortDesc != null) {
      map['he_short_desc'] = Variable<String>(heShortDesc);
    }
    if (!nullToAbsent || pubDate != null) {
      map['pub_date'] = Variable<String>(pubDate);
    }
    if (!nullToAbsent || pubPlace != null) {
      map['pub_place'] = Variable<String>(pubPlace);
    }
    map['topics'] = Variable<String>(topics);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || extraTitles != null) {
      map['extra_titles'] = Variable<String>(
          $BooksTable.$converterextraTitlesn.toSql(extraTitles));
    }
    if (!nullToAbsent || path != null) {
      map['path'] = Variable<String>(path);
    }
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] =
          Variable<String>($BooksTable.$convertermetadatan.toSql(metadata));
    }
    map['last_modified'] = Variable<DateTime>(lastModified);
    map['created'] = Variable<DateTime>(created);
    map['type'] = Variable<String>(type);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      title: Value(title),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      heShortDesc: heShortDesc == null && nullToAbsent
          ? const Value.absent()
          : Value(heShortDesc),
      pubDate: pubDate == null && nullToAbsent
          ? const Value.absent()
          : Value(pubDate),
      pubPlace: pubPlace == null && nullToAbsent
          ? const Value.absent()
          : Value(pubPlace),
      topics: Value(topics),
      order: Value(order),
      extraTitles: extraTitles == null && nullToAbsent
          ? const Value.absent()
          : Value(extraTitles),
      path: path == null && nullToAbsent ? const Value.absent() : Value(path),
      categoryId: Value(categoryId),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      lastModified: Value(lastModified),
      created: Value(created),
      type: Value(type),
    );
  }

  factory Book.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      heShortDesc: serializer.fromJson<String?>(json['heShortDesc']),
      pubDate: serializer.fromJson<String?>(json['pubDate']),
      pubPlace: serializer.fromJson<String?>(json['pubPlace']),
      topics: serializer.fromJson<String>(json['topics']),
      order: serializer.fromJson<int>(json['order']),
      extraTitles: serializer.fromJson<List<String>?>(json['extraTitles']),
      path: serializer.fromJson<String?>(json['path']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      metadata: serializer.fromJson<Map<String, dynamic>?>(json['metadata']),
      lastModified: serializer.fromJson<DateTime>(json['lastModified']),
      created: serializer.fromJson<DateTime>(json['created']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'heShortDesc': serializer.toJson<String?>(heShortDesc),
      'pubDate': serializer.toJson<String?>(pubDate),
      'pubPlace': serializer.toJson<String?>(pubPlace),
      'topics': serializer.toJson<String>(topics),
      'order': serializer.toJson<int>(order),
      'extraTitles': serializer.toJson<List<String>?>(extraTitles),
      'path': serializer.toJson<String?>(path),
      'categoryId': serializer.toJson<int>(categoryId),
      'metadata': serializer.toJson<Map<String, dynamic>?>(metadata),
      'lastModified': serializer.toJson<DateTime>(lastModified),
      'created': serializer.toJson<DateTime>(created),
      'type': serializer.toJson<String>(type),
    };
  }

  Book copyWith(
          {int? id,
          String? title,
          Value<String?> author = const Value.absent(),
          Value<String?> heShortDesc = const Value.absent(),
          Value<String?> pubDate = const Value.absent(),
          Value<String?> pubPlace = const Value.absent(),
          String? topics,
          int? order,
          Value<List<String>?> extraTitles = const Value.absent(),
          Value<String?> path = const Value.absent(),
          int? categoryId,
          Value<Map<String, dynamic>?> metadata = const Value.absent(),
          DateTime? lastModified,
          DateTime? created,
          String? type}) =>
      Book(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author.present ? author.value : this.author,
        heShortDesc: heShortDesc.present ? heShortDesc.value : this.heShortDesc,
        pubDate: pubDate.present ? pubDate.value : this.pubDate,
        pubPlace: pubPlace.present ? pubPlace.value : this.pubPlace,
        topics: topics ?? this.topics,
        order: order ?? this.order,
        extraTitles: extraTitles.present ? extraTitles.value : this.extraTitles,
        path: path.present ? path.value : this.path,
        categoryId: categoryId ?? this.categoryId,
        metadata: metadata.present ? metadata.value : this.metadata,
        lastModified: lastModified ?? this.lastModified,
        created: created ?? this.created,
        type: type ?? this.type,
      );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      heShortDesc:
          data.heShortDesc.present ? data.heShortDesc.value : this.heShortDesc,
      pubDate: data.pubDate.present ? data.pubDate.value : this.pubDate,
      pubPlace: data.pubPlace.present ? data.pubPlace.value : this.pubPlace,
      topics: data.topics.present ? data.topics.value : this.topics,
      order: data.order.present ? data.order.value : this.order,
      extraTitles:
          data.extraTitles.present ? data.extraTitles.value : this.extraTitles,
      path: data.path.present ? data.path.value : this.path,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      created: data.created.present ? data.created.value : this.created,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('heShortDesc: $heShortDesc, ')
          ..write('pubDate: $pubDate, ')
          ..write('pubPlace: $pubPlace, ')
          ..write('topics: $topics, ')
          ..write('order: $order, ')
          ..write('extraTitles: $extraTitles, ')
          ..write('path: $path, ')
          ..write('categoryId: $categoryId, ')
          ..write('metadata: $metadata, ')
          ..write('lastModified: $lastModified, ')
          ..write('created: $created, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      author,
      heShortDesc,
      pubDate,
      pubPlace,
      topics,
      order,
      extraTitles,
      path,
      categoryId,
      metadata,
      lastModified,
      created,
      type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.title == this.title &&
          other.author == this.author &&
          other.heShortDesc == this.heShortDesc &&
          other.pubDate == this.pubDate &&
          other.pubPlace == this.pubPlace &&
          other.topics == this.topics &&
          other.order == this.order &&
          other.extraTitles == this.extraTitles &&
          other.path == this.path &&
          other.categoryId == this.categoryId &&
          other.metadata == this.metadata &&
          other.lastModified == this.lastModified &&
          other.created == this.created &&
          other.type == this.type);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> heShortDesc;
  final Value<String?> pubDate;
  final Value<String?> pubPlace;
  final Value<String> topics;
  final Value<int> order;
  final Value<List<String>?> extraTitles;
  final Value<String?> path;
  final Value<int> categoryId;
  final Value<Map<String, dynamic>?> metadata;
  final Value<DateTime> lastModified;
  final Value<DateTime> created;
  final Value<String> type;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.heShortDesc = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.pubPlace = const Value.absent(),
    this.topics = const Value.absent(),
    this.order = const Value.absent(),
    this.extraTitles = const Value.absent(),
    this.path = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.metadata = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.created = const Value.absent(),
    this.type = const Value.absent(),
  });
  BooksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.author = const Value.absent(),
    this.heShortDesc = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.pubPlace = const Value.absent(),
    this.topics = const Value.absent(),
    this.order = const Value.absent(),
    this.extraTitles = const Value.absent(),
    this.path = const Value.absent(),
    required int categoryId,
    this.metadata = const Value.absent(),
    required DateTime lastModified,
    required DateTime created,
    required String type,
  })  : title = Value(title),
        categoryId = Value(categoryId),
        lastModified = Value(lastModified),
        created = Value(created),
        type = Value(type);
  static Insertable<Book> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? heShortDesc,
    Expression<String>? pubDate,
    Expression<String>? pubPlace,
    Expression<String>? topics,
    Expression<int>? order,
    Expression<String>? extraTitles,
    Expression<String>? path,
    Expression<int>? categoryId,
    Expression<String>? metadata,
    Expression<DateTime>? lastModified,
    Expression<DateTime>? created,
    Expression<String>? type,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (heShortDesc != null) 'he_short_desc': heShortDesc,
      if (pubDate != null) 'pub_date': pubDate,
      if (pubPlace != null) 'pub_place': pubPlace,
      if (topics != null) 'topics': topics,
      if (order != null) 'order': order,
      if (extraTitles != null) 'extra_titles': extraTitles,
      if (path != null) 'path': path,
      if (categoryId != null) 'category_id': categoryId,
      if (metadata != null) 'metadata': metadata,
      if (lastModified != null) 'last_modified': lastModified,
      if (created != null) 'created': created,
      if (type != null) 'type': type,
    });
  }

  BooksCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? author,
      Value<String?>? heShortDesc,
      Value<String?>? pubDate,
      Value<String?>? pubPlace,
      Value<String>? topics,
      Value<int>? order,
      Value<List<String>?>? extraTitles,
      Value<String?>? path,
      Value<int>? categoryId,
      Value<Map<String, dynamic>?>? metadata,
      Value<DateTime>? lastModified,
      Value<DateTime>? created,
      Value<String>? type}) {
    return BooksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      heShortDesc: heShortDesc ?? this.heShortDesc,
      pubDate: pubDate ?? this.pubDate,
      pubPlace: pubPlace ?? this.pubPlace,
      topics: topics ?? this.topics,
      order: order ?? this.order,
      extraTitles: extraTitles ?? this.extraTitles,
      path: path ?? this.path,
      categoryId: categoryId ?? this.categoryId,
      metadata: metadata ?? this.metadata,
      lastModified: lastModified ?? this.lastModified,
      created: created ?? this.created,
      type: type ?? this.type,
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
    if (heShortDesc.present) {
      map['he_short_desc'] = Variable<String>(heShortDesc.value);
    }
    if (pubDate.present) {
      map['pub_date'] = Variable<String>(pubDate.value);
    }
    if (pubPlace.present) {
      map['pub_place'] = Variable<String>(pubPlace.value);
    }
    if (topics.present) {
      map['topics'] = Variable<String>(topics.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (extraTitles.present) {
      map['extra_titles'] = Variable<String>(
          $BooksTable.$converterextraTitlesn.toSql(extraTitles.value));
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(
          $BooksTable.$convertermetadatan.toSql(metadata.value));
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('heShortDesc: $heShortDesc, ')
          ..write('pubDate: $pubDate, ')
          ..write('pubPlace: $pubPlace, ')
          ..write('topics: $topics, ')
          ..write('order: $order, ')
          ..write('extraTitles: $extraTitles, ')
          ..write('path: $path, ')
          ..write('categoryId: $categoryId, ')
          ..write('metadata: $metadata, ')
          ..write('lastModified: $lastModified, ')
          ..write('created: $created, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExternalBooksTable externalBooks = $ExternalBooksTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $BooksTable books = $BooksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [externalBooks, categories, books];
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

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String title,
  Value<int?> parentId,
  Value<String?> description,
  Value<String?> shortDescription,
  Value<int> order,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<int?> parentId,
  Value<String?> description,
  Value<String?> shortDescription,
  Value<int> order,
});

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CategoriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int?> parentId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> shortDescription = const Value.absent(),
            Value<int> order = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            title: title,
            parentId: parentId,
            description: description,
            shortDescription: shortDescription,
            order: order,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<int?> parentId = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> shortDescription = const Value.absent(),
            Value<int> order = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            title: title,
            parentId: parentId,
            description: description,
            shortDescription: shortDescription,
            order: order,
          ),
        ));
}

class $$CategoriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get shortDescription => $state.composableBuilder(
      column: $state.table.shortDescription,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter booksRefs(
      ComposableFilter Function($$BooksTableFilterComposer f) f) {
    final $$BooksTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.books,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder, parentComposers) => $$BooksTableFilterComposer(
            ComposerState(
                $state.db, $state.db.books, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get title => $state.composableBuilder(
      column: $state.table.title,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get description => $state.composableBuilder(
      column: $state.table.description,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get shortDescription => $state.composableBuilder(
      column: $state.table.shortDescription,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> author,
  Value<String?> heShortDesc,
  Value<String?> pubDate,
  Value<String?> pubPlace,
  Value<String> topics,
  Value<int> order,
  Value<List<String>?> extraTitles,
  Value<String?> path,
  required int categoryId,
  Value<Map<String, dynamic>?> metadata,
  required DateTime lastModified,
  required DateTime created,
  required String type,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> author,
  Value<String?> heShortDesc,
  Value<String?> pubDate,
  Value<String?> pubPlace,
  Value<String> topics,
  Value<int> order,
  Value<List<String>?> extraTitles,
  Value<String?> path,
  Value<int> categoryId,
  Value<Map<String, dynamic>?> metadata,
  Value<DateTime> lastModified,
  Value<DateTime> created,
  Value<String> type,
});

class $$BooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BooksTable,
    Book,
    $$BooksTableFilterComposer,
    $$BooksTableOrderingComposer,
    $$BooksTableCreateCompanionBuilder,
    $$BooksTableUpdateCompanionBuilder> {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$BooksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$BooksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<String?> heShortDesc = const Value.absent(),
            Value<String?> pubDate = const Value.absent(),
            Value<String?> pubPlace = const Value.absent(),
            Value<String> topics = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<List<String>?> extraTitles = const Value.absent(),
            Value<String?> path = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<Map<String, dynamic>?> metadata = const Value.absent(),
            Value<DateTime> lastModified = const Value.absent(),
            Value<DateTime> created = const Value.absent(),
            Value<String> type = const Value.absent(),
          }) =>
              BooksCompanion(
            id: id,
            title: title,
            author: author,
            heShortDesc: heShortDesc,
            pubDate: pubDate,
            pubPlace: pubPlace,
            topics: topics,
            order: order,
            extraTitles: extraTitles,
            path: path,
            categoryId: categoryId,
            metadata: metadata,
            lastModified: lastModified,
            created: created,
            type: type,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> author = const Value.absent(),
            Value<String?> heShortDesc = const Value.absent(),
            Value<String?> pubDate = const Value.absent(),
            Value<String?> pubPlace = const Value.absent(),
            Value<String> topics = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<List<String>?> extraTitles = const Value.absent(),
            Value<String?> path = const Value.absent(),
            required int categoryId,
            Value<Map<String, dynamic>?> metadata = const Value.absent(),
            required DateTime lastModified,
            required DateTime created,
            required String type,
          }) =>
              BooksCompanion.insert(
            id: id,
            title: title,
            author: author,
            heShortDesc: heShortDesc,
            pubDate: pubDate,
            pubPlace: pubPlace,
            topics: topics,
            order: order,
            extraTitles: extraTitles,
            path: path,
            categoryId: categoryId,
            metadata: metadata,
            lastModified: lastModified,
            created: created,
            type: type,
          ),
        ));
}

class $$BooksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer(super.$state);
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

  ColumnFilters<String> get heShortDesc => $state.composableBuilder(
      column: $state.table.heShortDesc,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pubDate => $state.composableBuilder(
      column: $state.table.pubDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get pubPlace => $state.composableBuilder(
      column: $state.table.pubPlace,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get topics => $state.composableBuilder(
      column: $state.table.topics,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
      get extraTitles => $state.composableBuilder(
          column: $state.table.extraTitles,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<String> get path => $state.composableBuilder(
      column: $state.table.path,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<Map<String, dynamic>?, Map<String, dynamic>,
          String>
      get metadata => $state.composableBuilder(
          column: $state.table.metadata,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get created => $state.composableBuilder(
      column: $state.table.created,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableFilterComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$BooksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer(super.$state);
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

  ColumnOrderings<String> get heShortDesc => $state.composableBuilder(
      column: $state.table.heShortDesc,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pubDate => $state.composableBuilder(
      column: $state.table.pubDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get pubPlace => $state.composableBuilder(
      column: $state.table.pubPlace,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get topics => $state.composableBuilder(
      column: $state.table.topics,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get extraTitles => $state.composableBuilder(
      column: $state.table.extraTitles,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get path => $state.composableBuilder(
      column: $state.table.path,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get metadata => $state.composableBuilder(
      column: $state.table.metadata,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastModified => $state.composableBuilder(
      column: $state.table.lastModified,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get created => $state.composableBuilder(
      column: $state.table.created,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $state.db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CategoriesTableOrderingComposer(ComposerState($state.db,
                $state.db.categories, joinBuilder, parentComposers)));
    return composer;
  }
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExternalBooksTableTableManager get externalBooks =>
      $$ExternalBooksTableTableManager(_db, _db.externalBooks);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
}
