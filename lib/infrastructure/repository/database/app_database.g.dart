// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StatementLinesTable extends StatementLines
    with TableInfo<$StatementLinesTable, StatementLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatementLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v7(),
  );
  static const VerificationMeta _duplicateKeyMeta = const VerificationMeta(
    'duplicateKey',
  );
  @override
  late final GeneratedColumn<String> duplicateKey = GeneratedColumn<String>(
    'duplicate_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _entranceAtMeta = const VerificationMeta(
    'entranceAt',
  );
  @override
  late final GeneratedColumn<DateTime> entranceAt = GeneratedColumn<DateTime>(
    'entrance_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exitAtMeta = const VerificationMeta('exitAt');
  @override
  late final GeneratedColumn<DateTime> exitAt = GeneratedColumn<DateTime>(
    'exit_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entranceIcMeta = const VerificationMeta(
    'entranceIc',
  );
  @override
  late final GeneratedColumn<String> entranceIc = GeneratedColumn<String>(
    'entrance_ic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exitIcMeta = const VerificationMeta('exitIc');
  @override
  late final GeneratedColumn<String> exitIc = GeneratedColumn<String>(
    'exit_ic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grossFareMeta = const VerificationMeta(
    'grossFare',
  );
  @override
  late final GeneratedColumn<int> grossFare = GeneratedColumn<int>(
    'gross_fare',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etcDiscountMeta = const VerificationMeta(
    'etcDiscount',
  );
  @override
  late final GeneratedColumn<int> etcDiscount = GeneratedColumn<int>(
    'etc_discount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fareMeta = const VerificationMeta('fare');
  @override
  late final GeneratedColumn<int> fare = GeneratedColumn<int>(
    'fare',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fareAfterRebateMeta = const VerificationMeta(
    'fareAfterRebate',
  );
  @override
  late final GeneratedColumn<int> fareAfterRebate = GeneratedColumn<int>(
    'fare_after_rebate',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _postpaidFareMeta = const VerificationMeta(
    'postpaidFare',
  );
  @override
  late final GeneratedColumn<int> postpaidFare = GeneratedColumn<int>(
    'postpaid_fare',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<VehicleTypeValue, int>
  vehicleType = GeneratedColumn<int>(
    'vehicle_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<VehicleTypeValue>($StatementLinesTable.$convertervehicleType);
  static const VerificationMeta _vehicleNumberMeta = const VerificationMeta(
    'vehicleNumber',
  );
  @override
  late final GeneratedColumn<int> vehicleNumber = GeneratedColumn<int>(
    'vehicle_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardNumberMeta = const VerificationMeta(
    'cardNumber',
  );
  @override
  late final GeneratedColumn<String> cardNumber = GeneratedColumn<String>(
    'card_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ConfirmationStatusValue, int>
  status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ConfirmationStatusValue>(
        $StatementLinesTable.$converterstatus,
      );
  static const VerificationMeta _discountTypesMeta = const VerificationMeta(
    'discountTypes',
  );
  @override
  late final GeneratedColumn<String> discountTypes = GeneratedColumn<String>(
    'discount_types',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    duplicateKey,
    entranceAt,
    exitAt,
    entranceIc,
    exitIc,
    grossFare,
    etcDiscount,
    fare,
    fareAfterRebate,
    postpaidFare,
    vehicleType,
    vehicleNumber,
    cardNumber,
    status,
    discountTypes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'statement_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<StatementLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('duplicate_key')) {
      context.handle(
        _duplicateKeyMeta,
        duplicateKey.isAcceptableOrUnknown(
          data['duplicate_key']!,
          _duplicateKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_duplicateKeyMeta);
    }
    if (data.containsKey('entrance_at')) {
      context.handle(
        _entranceAtMeta,
        entranceAt.isAcceptableOrUnknown(data['entrance_at']!, _entranceAtMeta),
      );
    }
    if (data.containsKey('exit_at')) {
      context.handle(
        _exitAtMeta,
        exitAt.isAcceptableOrUnknown(data['exit_at']!, _exitAtMeta),
      );
    } else if (isInserting) {
      context.missing(_exitAtMeta);
    }
    if (data.containsKey('entrance_ic')) {
      context.handle(
        _entranceIcMeta,
        entranceIc.isAcceptableOrUnknown(data['entrance_ic']!, _entranceIcMeta),
      );
    }
    if (data.containsKey('exit_ic')) {
      context.handle(
        _exitIcMeta,
        exitIc.isAcceptableOrUnknown(data['exit_ic']!, _exitIcMeta),
      );
    } else if (isInserting) {
      context.missing(_exitIcMeta);
    }
    if (data.containsKey('gross_fare')) {
      context.handle(
        _grossFareMeta,
        grossFare.isAcceptableOrUnknown(data['gross_fare']!, _grossFareMeta),
      );
    }
    if (data.containsKey('etc_discount')) {
      context.handle(
        _etcDiscountMeta,
        etcDiscount.isAcceptableOrUnknown(
          data['etc_discount']!,
          _etcDiscountMeta,
        ),
      );
    }
    if (data.containsKey('fare')) {
      context.handle(
        _fareMeta,
        fare.isAcceptableOrUnknown(data['fare']!, _fareMeta),
      );
    } else if (isInserting) {
      context.missing(_fareMeta);
    }
    if (data.containsKey('fare_after_rebate')) {
      context.handle(
        _fareAfterRebateMeta,
        fareAfterRebate.isAcceptableOrUnknown(
          data['fare_after_rebate']!,
          _fareAfterRebateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fareAfterRebateMeta);
    }
    if (data.containsKey('postpaid_fare')) {
      context.handle(
        _postpaidFareMeta,
        postpaidFare.isAcceptableOrUnknown(
          data['postpaid_fare']!,
          _postpaidFareMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_postpaidFareMeta);
    }
    if (data.containsKey('vehicle_number')) {
      context.handle(
        _vehicleNumberMeta,
        vehicleNumber.isAcceptableOrUnknown(
          data['vehicle_number']!,
          _vehicleNumberMeta,
        ),
      );
    }
    if (data.containsKey('card_number')) {
      context.handle(
        _cardNumberMeta,
        cardNumber.isAcceptableOrUnknown(data['card_number']!, _cardNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_cardNumberMeta);
    }
    if (data.containsKey('discount_types')) {
      context.handle(
        _discountTypesMeta,
        discountTypes.isAcceptableOrUnknown(
          data['discount_types']!,
          _discountTypesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountTypesMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StatementLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatementLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      duplicateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duplicate_key'],
      )!,
      entranceAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entrance_at'],
      ),
      exitAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}exit_at'],
      )!,
      entranceIc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entrance_ic'],
      ),
      exitIc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exit_ic'],
      )!,
      grossFare: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gross_fare'],
      ),
      etcDiscount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}etc_discount'],
      ),
      fare: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fare'],
      )!,
      fareAfterRebate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fare_after_rebate'],
      )!,
      postpaidFare: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}postpaid_fare'],
      )!,
      vehicleType: $StatementLinesTable.$convertervehicleType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}vehicle_type'],
        )!,
      ),
      vehicleNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vehicle_number'],
      ),
      cardNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_number'],
      )!,
      status: $StatementLinesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      discountTypes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_types'],
      )!,
    );
  }

  @override
  $StatementLinesTable createAlias(String alias) {
    return $StatementLinesTable(attachedDatabase, alias);
  }

  static TypeConverter<VehicleTypeValue, int> $convertervehicleType =
      const VehicleTypeConverter();
  static JsonTypeConverter2<ConfirmationStatusValue, int, int>
  $converterstatus = const EnumIndexConverter<ConfirmationStatusValue>(
    ConfirmationStatusValue.values,
  );
}

class StatementLine extends DataClass implements Insertable<StatementLine> {
  /// UUID version 7, made when the row is first stored.
  final String id;

  /// The duplicate key of docs/csv-format.md joined into one text.
  /// Entrance columns can be null, so a unique index on them would not work.
  final String duplicateKey;
  final DateTime? entranceAt;
  final DateTime exitAt;
  final String? entranceIc;
  final String exitIc;
  final int? grossFare;
  final int? etcDiscount;
  final int fare;
  final int fareAfterRebate;
  final int postpaidFare;

  /// The CSV number of the vehicle type (see [VehicleTypeValue]).
  final VehicleTypeValue vehicleType;

  /// Null when the CSV leaves it blank and the user has not entered one.
  final int? vehicleNumber;
  final String cardNumber;

  /// Stored as the position in [ConfirmationStatusValue] (0 confirmed, 1 pending).
  /// Do not reorder the enum.
  final ConfirmationStatusValue status;

  /// Discount types joined with `;`, like the CSV note. Empty when none.
  final String discountTypes;
  const StatementLine({
    required this.id,
    required this.duplicateKey,
    this.entranceAt,
    required this.exitAt,
    this.entranceIc,
    required this.exitIc,
    this.grossFare,
    this.etcDiscount,
    required this.fare,
    required this.fareAfterRebate,
    required this.postpaidFare,
    required this.vehicleType,
    this.vehicleNumber,
    required this.cardNumber,
    required this.status,
    required this.discountTypes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['duplicate_key'] = Variable<String>(duplicateKey);
    if (!nullToAbsent || entranceAt != null) {
      map['entrance_at'] = Variable<DateTime>(entranceAt);
    }
    map['exit_at'] = Variable<DateTime>(exitAt);
    if (!nullToAbsent || entranceIc != null) {
      map['entrance_ic'] = Variable<String>(entranceIc);
    }
    map['exit_ic'] = Variable<String>(exitIc);
    if (!nullToAbsent || grossFare != null) {
      map['gross_fare'] = Variable<int>(grossFare);
    }
    if (!nullToAbsent || etcDiscount != null) {
      map['etc_discount'] = Variable<int>(etcDiscount);
    }
    map['fare'] = Variable<int>(fare);
    map['fare_after_rebate'] = Variable<int>(fareAfterRebate);
    map['postpaid_fare'] = Variable<int>(postpaidFare);
    {
      map['vehicle_type'] = Variable<int>(
        $StatementLinesTable.$convertervehicleType.toSql(vehicleType),
      );
    }
    if (!nullToAbsent || vehicleNumber != null) {
      map['vehicle_number'] = Variable<int>(vehicleNumber);
    }
    map['card_number'] = Variable<String>(cardNumber);
    {
      map['status'] = Variable<int>(
        $StatementLinesTable.$converterstatus.toSql(status),
      );
    }
    map['discount_types'] = Variable<String>(discountTypes);
    return map;
  }

  StatementLinesCompanion toCompanion(bool nullToAbsent) {
    return StatementLinesCompanion(
      id: Value(id),
      duplicateKey: Value(duplicateKey),
      entranceAt: entranceAt == null && nullToAbsent
          ? const Value.absent()
          : Value(entranceAt),
      exitAt: Value(exitAt),
      entranceIc: entranceIc == null && nullToAbsent
          ? const Value.absent()
          : Value(entranceIc),
      exitIc: Value(exitIc),
      grossFare: grossFare == null && nullToAbsent
          ? const Value.absent()
          : Value(grossFare),
      etcDiscount: etcDiscount == null && nullToAbsent
          ? const Value.absent()
          : Value(etcDiscount),
      fare: Value(fare),
      fareAfterRebate: Value(fareAfterRebate),
      postpaidFare: Value(postpaidFare),
      vehicleType: Value(vehicleType),
      vehicleNumber: vehicleNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(vehicleNumber),
      cardNumber: Value(cardNumber),
      status: Value(status),
      discountTypes: Value(discountTypes),
    );
  }

  factory StatementLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatementLine(
      id: serializer.fromJson<String>(json['id']),
      duplicateKey: serializer.fromJson<String>(json['duplicateKey']),
      entranceAt: serializer.fromJson<DateTime?>(json['entranceAt']),
      exitAt: serializer.fromJson<DateTime>(json['exitAt']),
      entranceIc: serializer.fromJson<String?>(json['entranceIc']),
      exitIc: serializer.fromJson<String>(json['exitIc']),
      grossFare: serializer.fromJson<int?>(json['grossFare']),
      etcDiscount: serializer.fromJson<int?>(json['etcDiscount']),
      fare: serializer.fromJson<int>(json['fare']),
      fareAfterRebate: serializer.fromJson<int>(json['fareAfterRebate']),
      postpaidFare: serializer.fromJson<int>(json['postpaidFare']),
      vehicleType: serializer.fromJson<VehicleTypeValue>(json['vehicleType']),
      vehicleNumber: serializer.fromJson<int?>(json['vehicleNumber']),
      cardNumber: serializer.fromJson<String>(json['cardNumber']),
      status: $StatementLinesTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      discountTypes: serializer.fromJson<String>(json['discountTypes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'duplicateKey': serializer.toJson<String>(duplicateKey),
      'entranceAt': serializer.toJson<DateTime?>(entranceAt),
      'exitAt': serializer.toJson<DateTime>(exitAt),
      'entranceIc': serializer.toJson<String?>(entranceIc),
      'exitIc': serializer.toJson<String>(exitIc),
      'grossFare': serializer.toJson<int?>(grossFare),
      'etcDiscount': serializer.toJson<int?>(etcDiscount),
      'fare': serializer.toJson<int>(fare),
      'fareAfterRebate': serializer.toJson<int>(fareAfterRebate),
      'postpaidFare': serializer.toJson<int>(postpaidFare),
      'vehicleType': serializer.toJson<VehicleTypeValue>(vehicleType),
      'vehicleNumber': serializer.toJson<int?>(vehicleNumber),
      'cardNumber': serializer.toJson<String>(cardNumber),
      'status': serializer.toJson<int>(
        $StatementLinesTable.$converterstatus.toJson(status),
      ),
      'discountTypes': serializer.toJson<String>(discountTypes),
    };
  }

  StatementLine copyWith({
    String? id,
    String? duplicateKey,
    Value<DateTime?> entranceAt = const Value.absent(),
    DateTime? exitAt,
    Value<String?> entranceIc = const Value.absent(),
    String? exitIc,
    Value<int?> grossFare = const Value.absent(),
    Value<int?> etcDiscount = const Value.absent(),
    int? fare,
    int? fareAfterRebate,
    int? postpaidFare,
    VehicleTypeValue? vehicleType,
    Value<int?> vehicleNumber = const Value.absent(),
    String? cardNumber,
    ConfirmationStatusValue? status,
    String? discountTypes,
  }) => StatementLine(
    id: id ?? this.id,
    duplicateKey: duplicateKey ?? this.duplicateKey,
    entranceAt: entranceAt.present ? entranceAt.value : this.entranceAt,
    exitAt: exitAt ?? this.exitAt,
    entranceIc: entranceIc.present ? entranceIc.value : this.entranceIc,
    exitIc: exitIc ?? this.exitIc,
    grossFare: grossFare.present ? grossFare.value : this.grossFare,
    etcDiscount: etcDiscount.present ? etcDiscount.value : this.etcDiscount,
    fare: fare ?? this.fare,
    fareAfterRebate: fareAfterRebate ?? this.fareAfterRebate,
    postpaidFare: postpaidFare ?? this.postpaidFare,
    vehicleType: vehicleType ?? this.vehicleType,
    vehicleNumber: vehicleNumber.present
        ? vehicleNumber.value
        : this.vehicleNumber,
    cardNumber: cardNumber ?? this.cardNumber,
    status: status ?? this.status,
    discountTypes: discountTypes ?? this.discountTypes,
  );
  StatementLine copyWithCompanion(StatementLinesCompanion data) {
    return StatementLine(
      id: data.id.present ? data.id.value : this.id,
      duplicateKey: data.duplicateKey.present
          ? data.duplicateKey.value
          : this.duplicateKey,
      entranceAt: data.entranceAt.present
          ? data.entranceAt.value
          : this.entranceAt,
      exitAt: data.exitAt.present ? data.exitAt.value : this.exitAt,
      entranceIc: data.entranceIc.present
          ? data.entranceIc.value
          : this.entranceIc,
      exitIc: data.exitIc.present ? data.exitIc.value : this.exitIc,
      grossFare: data.grossFare.present ? data.grossFare.value : this.grossFare,
      etcDiscount: data.etcDiscount.present
          ? data.etcDiscount.value
          : this.etcDiscount,
      fare: data.fare.present ? data.fare.value : this.fare,
      fareAfterRebate: data.fareAfterRebate.present
          ? data.fareAfterRebate.value
          : this.fareAfterRebate,
      postpaidFare: data.postpaidFare.present
          ? data.postpaidFare.value
          : this.postpaidFare,
      vehicleType: data.vehicleType.present
          ? data.vehicleType.value
          : this.vehicleType,
      vehicleNumber: data.vehicleNumber.present
          ? data.vehicleNumber.value
          : this.vehicleNumber,
      cardNumber: data.cardNumber.present
          ? data.cardNumber.value
          : this.cardNumber,
      status: data.status.present ? data.status.value : this.status,
      discountTypes: data.discountTypes.present
          ? data.discountTypes.value
          : this.discountTypes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatementLine(')
          ..write('id: $id, ')
          ..write('duplicateKey: $duplicateKey, ')
          ..write('entranceAt: $entranceAt, ')
          ..write('exitAt: $exitAt, ')
          ..write('entranceIc: $entranceIc, ')
          ..write('exitIc: $exitIc, ')
          ..write('grossFare: $grossFare, ')
          ..write('etcDiscount: $etcDiscount, ')
          ..write('fare: $fare, ')
          ..write('fareAfterRebate: $fareAfterRebate, ')
          ..write('postpaidFare: $postpaidFare, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('vehicleNumber: $vehicleNumber, ')
          ..write('cardNumber: $cardNumber, ')
          ..write('status: $status, ')
          ..write('discountTypes: $discountTypes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    duplicateKey,
    entranceAt,
    exitAt,
    entranceIc,
    exitIc,
    grossFare,
    etcDiscount,
    fare,
    fareAfterRebate,
    postpaidFare,
    vehicleType,
    vehicleNumber,
    cardNumber,
    status,
    discountTypes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatementLine &&
          other.id == this.id &&
          other.duplicateKey == this.duplicateKey &&
          other.entranceAt == this.entranceAt &&
          other.exitAt == this.exitAt &&
          other.entranceIc == this.entranceIc &&
          other.exitIc == this.exitIc &&
          other.grossFare == this.grossFare &&
          other.etcDiscount == this.etcDiscount &&
          other.fare == this.fare &&
          other.fareAfterRebate == this.fareAfterRebate &&
          other.postpaidFare == this.postpaidFare &&
          other.vehicleType == this.vehicleType &&
          other.vehicleNumber == this.vehicleNumber &&
          other.cardNumber == this.cardNumber &&
          other.status == this.status &&
          other.discountTypes == this.discountTypes);
}

class StatementLinesCompanion extends UpdateCompanion<StatementLine> {
  final Value<String> id;
  final Value<String> duplicateKey;
  final Value<DateTime?> entranceAt;
  final Value<DateTime> exitAt;
  final Value<String?> entranceIc;
  final Value<String> exitIc;
  final Value<int?> grossFare;
  final Value<int?> etcDiscount;
  final Value<int> fare;
  final Value<int> fareAfterRebate;
  final Value<int> postpaidFare;
  final Value<VehicleTypeValue> vehicleType;
  final Value<int?> vehicleNumber;
  final Value<String> cardNumber;
  final Value<ConfirmationStatusValue> status;
  final Value<String> discountTypes;
  final Value<int> rowid;
  const StatementLinesCompanion({
    this.id = const Value.absent(),
    this.duplicateKey = const Value.absent(),
    this.entranceAt = const Value.absent(),
    this.exitAt = const Value.absent(),
    this.entranceIc = const Value.absent(),
    this.exitIc = const Value.absent(),
    this.grossFare = const Value.absent(),
    this.etcDiscount = const Value.absent(),
    this.fare = const Value.absent(),
    this.fareAfterRebate = const Value.absent(),
    this.postpaidFare = const Value.absent(),
    this.vehicleType = const Value.absent(),
    this.vehicleNumber = const Value.absent(),
    this.cardNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.discountTypes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StatementLinesCompanion.insert({
    this.id = const Value.absent(),
    required String duplicateKey,
    this.entranceAt = const Value.absent(),
    required DateTime exitAt,
    this.entranceIc = const Value.absent(),
    required String exitIc,
    this.grossFare = const Value.absent(),
    this.etcDiscount = const Value.absent(),
    required int fare,
    required int fareAfterRebate,
    required int postpaidFare,
    required VehicleTypeValue vehicleType,
    this.vehicleNumber = const Value.absent(),
    required String cardNumber,
    required ConfirmationStatusValue status,
    required String discountTypes,
    this.rowid = const Value.absent(),
  }) : duplicateKey = Value(duplicateKey),
       exitAt = Value(exitAt),
       exitIc = Value(exitIc),
       fare = Value(fare),
       fareAfterRebate = Value(fareAfterRebate),
       postpaidFare = Value(postpaidFare),
       vehicleType = Value(vehicleType),
       cardNumber = Value(cardNumber),
       status = Value(status),
       discountTypes = Value(discountTypes);
  static Insertable<StatementLine> custom({
    Expression<String>? id,
    Expression<String>? duplicateKey,
    Expression<DateTime>? entranceAt,
    Expression<DateTime>? exitAt,
    Expression<String>? entranceIc,
    Expression<String>? exitIc,
    Expression<int>? grossFare,
    Expression<int>? etcDiscount,
    Expression<int>? fare,
    Expression<int>? fareAfterRebate,
    Expression<int>? postpaidFare,
    Expression<int>? vehicleType,
    Expression<int>? vehicleNumber,
    Expression<String>? cardNumber,
    Expression<int>? status,
    Expression<String>? discountTypes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (duplicateKey != null) 'duplicate_key': duplicateKey,
      if (entranceAt != null) 'entrance_at': entranceAt,
      if (exitAt != null) 'exit_at': exitAt,
      if (entranceIc != null) 'entrance_ic': entranceIc,
      if (exitIc != null) 'exit_ic': exitIc,
      if (grossFare != null) 'gross_fare': grossFare,
      if (etcDiscount != null) 'etc_discount': etcDiscount,
      if (fare != null) 'fare': fare,
      if (fareAfterRebate != null) 'fare_after_rebate': fareAfterRebate,
      if (postpaidFare != null) 'postpaid_fare': postpaidFare,
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (vehicleNumber != null) 'vehicle_number': vehicleNumber,
      if (cardNumber != null) 'card_number': cardNumber,
      if (status != null) 'status': status,
      if (discountTypes != null) 'discount_types': discountTypes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StatementLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? duplicateKey,
    Value<DateTime?>? entranceAt,
    Value<DateTime>? exitAt,
    Value<String?>? entranceIc,
    Value<String>? exitIc,
    Value<int?>? grossFare,
    Value<int?>? etcDiscount,
    Value<int>? fare,
    Value<int>? fareAfterRebate,
    Value<int>? postpaidFare,
    Value<VehicleTypeValue>? vehicleType,
    Value<int?>? vehicleNumber,
    Value<String>? cardNumber,
    Value<ConfirmationStatusValue>? status,
    Value<String>? discountTypes,
    Value<int>? rowid,
  }) {
    return StatementLinesCompanion(
      id: id ?? this.id,
      duplicateKey: duplicateKey ?? this.duplicateKey,
      entranceAt: entranceAt ?? this.entranceAt,
      exitAt: exitAt ?? this.exitAt,
      entranceIc: entranceIc ?? this.entranceIc,
      exitIc: exitIc ?? this.exitIc,
      grossFare: grossFare ?? this.grossFare,
      etcDiscount: etcDiscount ?? this.etcDiscount,
      fare: fare ?? this.fare,
      fareAfterRebate: fareAfterRebate ?? this.fareAfterRebate,
      postpaidFare: postpaidFare ?? this.postpaidFare,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      cardNumber: cardNumber ?? this.cardNumber,
      status: status ?? this.status,
      discountTypes: discountTypes ?? this.discountTypes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (duplicateKey.present) {
      map['duplicate_key'] = Variable<String>(duplicateKey.value);
    }
    if (entranceAt.present) {
      map['entrance_at'] = Variable<DateTime>(entranceAt.value);
    }
    if (exitAt.present) {
      map['exit_at'] = Variable<DateTime>(exitAt.value);
    }
    if (entranceIc.present) {
      map['entrance_ic'] = Variable<String>(entranceIc.value);
    }
    if (exitIc.present) {
      map['exit_ic'] = Variable<String>(exitIc.value);
    }
    if (grossFare.present) {
      map['gross_fare'] = Variable<int>(grossFare.value);
    }
    if (etcDiscount.present) {
      map['etc_discount'] = Variable<int>(etcDiscount.value);
    }
    if (fare.present) {
      map['fare'] = Variable<int>(fare.value);
    }
    if (fareAfterRebate.present) {
      map['fare_after_rebate'] = Variable<int>(fareAfterRebate.value);
    }
    if (postpaidFare.present) {
      map['postpaid_fare'] = Variable<int>(postpaidFare.value);
    }
    if (vehicleType.present) {
      map['vehicle_type'] = Variable<int>(
        $StatementLinesTable.$convertervehicleType.toSql(vehicleType.value),
      );
    }
    if (vehicleNumber.present) {
      map['vehicle_number'] = Variable<int>(vehicleNumber.value);
    }
    if (cardNumber.present) {
      map['card_number'] = Variable<String>(cardNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $StatementLinesTable.$converterstatus.toSql(status.value),
      );
    }
    if (discountTypes.present) {
      map['discount_types'] = Variable<String>(discountTypes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatementLinesCompanion(')
          ..write('id: $id, ')
          ..write('duplicateKey: $duplicateKey, ')
          ..write('entranceAt: $entranceAt, ')
          ..write('exitAt: $exitAt, ')
          ..write('entranceIc: $entranceIc, ')
          ..write('exitIc: $exitIc, ')
          ..write('grossFare: $grossFare, ')
          ..write('etcDiscount: $etcDiscount, ')
          ..write('fare: $fare, ')
          ..write('fareAfterRebate: $fareAfterRebate, ')
          ..write('postpaidFare: $postpaidFare, ')
          ..write('vehicleType: $vehicleType, ')
          ..write('vehicleNumber: $vehicleNumber, ')
          ..write('cardNumber: $cardNumber, ')
          ..write('status: $status, ')
          ..write('discountTypes: $discountTypes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IcMappingsTable extends IcMappings
    with TableInfo<$IcMappingsTable, IcMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IcMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _icNameMeta = const VerificationMeta('icName');
  @override
  late final GeneratedColumn<String> icName = GeneratedColumn<String>(
    'ic_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointIdMeta = const VerificationMeta(
    'pointId',
  );
  @override
  late final GeneratedColumn<String> pointId = GeneratedColumn<String>(
    'point_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [icName, pointId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ic_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<IcMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ic_name')) {
      context.handle(
        _icNameMeta,
        icName.isAcceptableOrUnknown(data['ic_name']!, _icNameMeta),
      );
    } else if (isInserting) {
      context.missing(_icNameMeta);
    }
    if (data.containsKey('point_id')) {
      context.handle(
        _pointIdMeta,
        pointId.isAcceptableOrUnknown(data['point_id']!, _pointIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pointIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {icName};
  @override
  IcMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IcMapping(
      icName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ic_name'],
      )!,
      pointId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}point_id'],
      )!,
    );
  }

  @override
  $IcMappingsTable createAlias(String alias) {
    return $IcMappingsTable(attachedDatabase, alias);
  }
}

class IcMapping extends DataClass implements Insertable<IcMapping> {
  /// The IC name as written in the CSV.
  final String icName;

  /// The id of the IC point in the IC master.
  final String pointId;
  const IcMapping({required this.icName, required this.pointId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ic_name'] = Variable<String>(icName);
    map['point_id'] = Variable<String>(pointId);
    return map;
  }

  IcMappingsCompanion toCompanion(bool nullToAbsent) {
    return IcMappingsCompanion(icName: Value(icName), pointId: Value(pointId));
  }

  factory IcMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IcMapping(
      icName: serializer.fromJson<String>(json['icName']),
      pointId: serializer.fromJson<String>(json['pointId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'icName': serializer.toJson<String>(icName),
      'pointId': serializer.toJson<String>(pointId),
    };
  }

  IcMapping copyWith({String? icName, String? pointId}) => IcMapping(
    icName: icName ?? this.icName,
    pointId: pointId ?? this.pointId,
  );
  IcMapping copyWithCompanion(IcMappingsCompanion data) {
    return IcMapping(
      icName: data.icName.present ? data.icName.value : this.icName,
      pointId: data.pointId.present ? data.pointId.value : this.pointId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IcMapping(')
          ..write('icName: $icName, ')
          ..write('pointId: $pointId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(icName, pointId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IcMapping &&
          other.icName == this.icName &&
          other.pointId == this.pointId);
}

class IcMappingsCompanion extends UpdateCompanion<IcMapping> {
  final Value<String> icName;
  final Value<String> pointId;
  final Value<int> rowid;
  const IcMappingsCompanion({
    this.icName = const Value.absent(),
    this.pointId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IcMappingsCompanion.insert({
    required String icName,
    required String pointId,
    this.rowid = const Value.absent(),
  }) : icName = Value(icName),
       pointId = Value(pointId);
  static Insertable<IcMapping> custom({
    Expression<String>? icName,
    Expression<String>? pointId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (icName != null) 'ic_name': icName,
      if (pointId != null) 'point_id': pointId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IcMappingsCompanion copyWith({
    Value<String>? icName,
    Value<String>? pointId,
    Value<int>? rowid,
  }) {
    return IcMappingsCompanion(
      icName: icName ?? this.icName,
      pointId: pointId ?? this.pointId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (icName.present) {
      map['ic_name'] = Variable<String>(icName.value);
    }
    if (pointId.present) {
      map['point_id'] = Variable<String>(pointId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IcMappingsCompanion(')
          ..write('icName: $icName, ')
          ..write('pointId: $pointId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IcPositionsTable extends IcPositions
    with TableInfo<$IcPositionsTable, IcPosition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IcPositionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _icNameMeta = const VerificationMeta('icName');
  @override
  late final GeneratedColumn<String> icName = GeneratedColumn<String>(
    'ic_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [icName, latitude, longitude];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ic_positions';
  @override
  VerificationContext validateIntegrity(
    Insertable<IcPosition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ic_name')) {
      context.handle(
        _icNameMeta,
        icName.isAcceptableOrUnknown(data['ic_name']!, _icNameMeta),
      );
    } else if (isInserting) {
      context.missing(_icNameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {icName};
  @override
  IcPosition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IcPosition(
      icName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ic_name'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
    );
  }

  @override
  $IcPositionsTable createAlias(String alias) {
    return $IcPositionsTable(attachedDatabase, alias);
  }
}

class IcPosition extends DataClass implements Insertable<IcPosition> {
  /// The IC name as written in the CSV.
  final String icName;

  /// Degrees.
  final double latitude;
  final double longitude;
  const IcPosition({
    required this.icName,
    required this.latitude,
    required this.longitude,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ic_name'] = Variable<String>(icName);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    return map;
  }

  IcPositionsCompanion toCompanion(bool nullToAbsent) {
    return IcPositionsCompanion(
      icName: Value(icName),
      latitude: Value(latitude),
      longitude: Value(longitude),
    );
  }

  factory IcPosition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IcPosition(
      icName: serializer.fromJson<String>(json['icName']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'icName': serializer.toJson<String>(icName),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
    };
  }

  IcPosition copyWith({String? icName, double? latitude, double? longitude}) =>
      IcPosition(
        icName: icName ?? this.icName,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
  IcPosition copyWithCompanion(IcPositionsCompanion data) {
    return IcPosition(
      icName: data.icName.present ? data.icName.value : this.icName,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IcPosition(')
          ..write('icName: $icName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(icName, latitude, longitude);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IcPosition &&
          other.icName == this.icName &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude);
}

class IcPositionsCompanion extends UpdateCompanion<IcPosition> {
  final Value<String> icName;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> rowid;
  const IcPositionsCompanion({
    this.icName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IcPositionsCompanion.insert({
    required String icName,
    required double latitude,
    required double longitude,
    this.rowid = const Value.absent(),
  }) : icName = Value(icName),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<IcPosition> custom({
    Expression<String>? icName,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (icName != null) 'ic_name': icName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IcPositionsCompanion copyWith({
    Value<String>? icName,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<int>? rowid,
  }) {
    return IcPositionsCompanion(
      icName: icName ?? this.icName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (icName.present) {
      map['ic_name'] = Variable<String>(icName.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IcPositionsCompanion(')
          ..write('icName: $icName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StatementLinesTable statementLines = $StatementLinesTable(this);
  late final $IcMappingsTable icMappings = $IcMappingsTable(this);
  late final $IcPositionsTable icPositions = $IcPositionsTable(this);
  late final Index statementLinesExitAt = Index(
    'statement_lines_exit_at',
    'CREATE INDEX statement_lines_exit_at ON statement_lines (exit_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    statementLines,
    icMappings,
    icPositions,
    statementLinesExitAt,
  ];
}

typedef $$StatementLinesTableCreateCompanionBuilder =
    StatementLinesCompanion Function({
      Value<String> id,
      required String duplicateKey,
      Value<DateTime?> entranceAt,
      required DateTime exitAt,
      Value<String?> entranceIc,
      required String exitIc,
      Value<int?> grossFare,
      Value<int?> etcDiscount,
      required int fare,
      required int fareAfterRebate,
      required int postpaidFare,
      required VehicleTypeValue vehicleType,
      Value<int?> vehicleNumber,
      required String cardNumber,
      required ConfirmationStatusValue status,
      required String discountTypes,
      Value<int> rowid,
    });
typedef $$StatementLinesTableUpdateCompanionBuilder =
    StatementLinesCompanion Function({
      Value<String> id,
      Value<String> duplicateKey,
      Value<DateTime?> entranceAt,
      Value<DateTime> exitAt,
      Value<String?> entranceIc,
      Value<String> exitIc,
      Value<int?> grossFare,
      Value<int?> etcDiscount,
      Value<int> fare,
      Value<int> fareAfterRebate,
      Value<int> postpaidFare,
      Value<VehicleTypeValue> vehicleType,
      Value<int?> vehicleNumber,
      Value<String> cardNumber,
      Value<ConfirmationStatusValue> status,
      Value<String> discountTypes,
      Value<int> rowid,
    });

class $$StatementLinesTableFilterComposer
    extends Composer<_$AppDatabase, $StatementLinesTable> {
  $$StatementLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duplicateKey => $composableBuilder(
    column: $table.duplicateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get entranceAt => $composableBuilder(
    column: $table.entranceAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get exitAt => $composableBuilder(
    column: $table.exitAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entranceIc => $composableBuilder(
    column: $table.entranceIc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exitIc => $composableBuilder(
    column: $table.exitIc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grossFare => $composableBuilder(
    column: $table.grossFare,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get etcDiscount => $composableBuilder(
    column: $table.etcDiscount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fare => $composableBuilder(
    column: $table.fare,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fareAfterRebate => $composableBuilder(
    column: $table.fareAfterRebate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get postpaidFare => $composableBuilder(
    column: $table.postpaidFare,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<VehicleTypeValue, VehicleTypeValue, int>
  get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get vehicleNumber => $composableBuilder(
    column: $table.vehicleNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardNumber => $composableBuilder(
    column: $table.cardNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ConfirmationStatusValue,
    ConfirmationStatusValue,
    int
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get discountTypes => $composableBuilder(
    column: $table.discountTypes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StatementLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $StatementLinesTable> {
  $$StatementLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duplicateKey => $composableBuilder(
    column: $table.duplicateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get entranceAt => $composableBuilder(
    column: $table.entranceAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get exitAt => $composableBuilder(
    column: $table.exitAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entranceIc => $composableBuilder(
    column: $table.entranceIc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exitIc => $composableBuilder(
    column: $table.exitIc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grossFare => $composableBuilder(
    column: $table.grossFare,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get etcDiscount => $composableBuilder(
    column: $table.etcDiscount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fare => $composableBuilder(
    column: $table.fare,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fareAfterRebate => $composableBuilder(
    column: $table.fareAfterRebate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get postpaidFare => $composableBuilder(
    column: $table.postpaidFare,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vehicleNumber => $composableBuilder(
    column: $table.vehicleNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardNumber => $composableBuilder(
    column: $table.cardNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountTypes => $composableBuilder(
    column: $table.discountTypes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StatementLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StatementLinesTable> {
  $$StatementLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get duplicateKey => $composableBuilder(
    column: $table.duplicateKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get entranceAt => $composableBuilder(
    column: $table.entranceAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get exitAt =>
      $composableBuilder(column: $table.exitAt, builder: (column) => column);

  GeneratedColumn<String> get entranceIc => $composableBuilder(
    column: $table.entranceIc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exitIc =>
      $composableBuilder(column: $table.exitIc, builder: (column) => column);

  GeneratedColumn<int> get grossFare =>
      $composableBuilder(column: $table.grossFare, builder: (column) => column);

  GeneratedColumn<int> get etcDiscount => $composableBuilder(
    column: $table.etcDiscount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fare =>
      $composableBuilder(column: $table.fare, builder: (column) => column);

  GeneratedColumn<int> get fareAfterRebate => $composableBuilder(
    column: $table.fareAfterRebate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get postpaidFare => $composableBuilder(
    column: $table.postpaidFare,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<VehicleTypeValue, int> get vehicleType =>
      $composableBuilder(
        column: $table.vehicleType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get vehicleNumber => $composableBuilder(
    column: $table.vehicleNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardNumber => $composableBuilder(
    column: $table.cardNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ConfirmationStatusValue, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get discountTypes => $composableBuilder(
    column: $table.discountTypes,
    builder: (column) => column,
  );
}

class $$StatementLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StatementLinesTable,
          StatementLine,
          $$StatementLinesTableFilterComposer,
          $$StatementLinesTableOrderingComposer,
          $$StatementLinesTableAnnotationComposer,
          $$StatementLinesTableCreateCompanionBuilder,
          $$StatementLinesTableUpdateCompanionBuilder,
          (
            StatementLine,
            BaseReferences<_$AppDatabase, $StatementLinesTable, StatementLine>,
          ),
          StatementLine,
          PrefetchHooks Function()
        > {
  $$StatementLinesTableTableManager(
    _$AppDatabase db,
    $StatementLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatementLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatementLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatementLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> duplicateKey = const Value.absent(),
                Value<DateTime?> entranceAt = const Value.absent(),
                Value<DateTime> exitAt = const Value.absent(),
                Value<String?> entranceIc = const Value.absent(),
                Value<String> exitIc = const Value.absent(),
                Value<int?> grossFare = const Value.absent(),
                Value<int?> etcDiscount = const Value.absent(),
                Value<int> fare = const Value.absent(),
                Value<int> fareAfterRebate = const Value.absent(),
                Value<int> postpaidFare = const Value.absent(),
                Value<VehicleTypeValue> vehicleType = const Value.absent(),
                Value<int?> vehicleNumber = const Value.absent(),
                Value<String> cardNumber = const Value.absent(),
                Value<ConfirmationStatusValue> status = const Value.absent(),
                Value<String> discountTypes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StatementLinesCompanion(
                id: id,
                duplicateKey: duplicateKey,
                entranceAt: entranceAt,
                exitAt: exitAt,
                entranceIc: entranceIc,
                exitIc: exitIc,
                grossFare: grossFare,
                etcDiscount: etcDiscount,
                fare: fare,
                fareAfterRebate: fareAfterRebate,
                postpaidFare: postpaidFare,
                vehicleType: vehicleType,
                vehicleNumber: vehicleNumber,
                cardNumber: cardNumber,
                status: status,
                discountTypes: discountTypes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String duplicateKey,
                Value<DateTime?> entranceAt = const Value.absent(),
                required DateTime exitAt,
                Value<String?> entranceIc = const Value.absent(),
                required String exitIc,
                Value<int?> grossFare = const Value.absent(),
                Value<int?> etcDiscount = const Value.absent(),
                required int fare,
                required int fareAfterRebate,
                required int postpaidFare,
                required VehicleTypeValue vehicleType,
                Value<int?> vehicleNumber = const Value.absent(),
                required String cardNumber,
                required ConfirmationStatusValue status,
                required String discountTypes,
                Value<int> rowid = const Value.absent(),
              }) => StatementLinesCompanion.insert(
                id: id,
                duplicateKey: duplicateKey,
                entranceAt: entranceAt,
                exitAt: exitAt,
                entranceIc: entranceIc,
                exitIc: exitIc,
                grossFare: grossFare,
                etcDiscount: etcDiscount,
                fare: fare,
                fareAfterRebate: fareAfterRebate,
                postpaidFare: postpaidFare,
                vehicleType: vehicleType,
                vehicleNumber: vehicleNumber,
                cardNumber: cardNumber,
                status: status,
                discountTypes: discountTypes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StatementLinesTable, StatementLine>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StatementLinesTable,
                    StatementLine
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StatementLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StatementLinesTable,
      StatementLine,
      $$StatementLinesTableFilterComposer,
      $$StatementLinesTableOrderingComposer,
      $$StatementLinesTableAnnotationComposer,
      $$StatementLinesTableCreateCompanionBuilder,
      $$StatementLinesTableUpdateCompanionBuilder,
      (
        StatementLine,
        BaseReferences<_$AppDatabase, $StatementLinesTable, StatementLine>,
      ),
      StatementLine,
      PrefetchHooks Function()
    >;
typedef $$IcMappingsTableCreateCompanionBuilder =
    IcMappingsCompanion Function({
      required String icName,
      required String pointId,
      Value<int> rowid,
    });
typedef $$IcMappingsTableUpdateCompanionBuilder =
    IcMappingsCompanion Function({
      Value<String> icName,
      Value<String> pointId,
      Value<int> rowid,
    });

class $$IcMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $IcMappingsTable> {
  $$IcMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get icName => $composableBuilder(
    column: $table.icName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pointId => $composableBuilder(
    column: $table.pointId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IcMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $IcMappingsTable> {
  $$IcMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get icName => $composableBuilder(
    column: $table.icName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pointId => $composableBuilder(
    column: $table.pointId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IcMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IcMappingsTable> {
  $$IcMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get icName =>
      $composableBuilder(column: $table.icName, builder: (column) => column);

  GeneratedColumn<String> get pointId =>
      $composableBuilder(column: $table.pointId, builder: (column) => column);
}

class $$IcMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IcMappingsTable,
          IcMapping,
          $$IcMappingsTableFilterComposer,
          $$IcMappingsTableOrderingComposer,
          $$IcMappingsTableAnnotationComposer,
          $$IcMappingsTableCreateCompanionBuilder,
          $$IcMappingsTableUpdateCompanionBuilder,
          (
            IcMapping,
            BaseReferences<_$AppDatabase, $IcMappingsTable, IcMapping>,
          ),
          IcMapping,
          PrefetchHooks Function()
        > {
  $$IcMappingsTableTableManager(_$AppDatabase db, $IcMappingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IcMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IcMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IcMappingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> icName = const Value.absent(),
                Value<String> pointId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IcMappingsCompanion(
                icName: icName,
                pointId: pointId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String icName,
                required String pointId,
                Value<int> rowid = const Value.absent(),
              }) => IcMappingsCompanion.insert(
                icName: icName,
                pointId: pointId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IcMappingsTable, IcMapping>(table),
                  BaseReferences<_$AppDatabase, $IcMappingsTable, IcMapping>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IcMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IcMappingsTable,
      IcMapping,
      $$IcMappingsTableFilterComposer,
      $$IcMappingsTableOrderingComposer,
      $$IcMappingsTableAnnotationComposer,
      $$IcMappingsTableCreateCompanionBuilder,
      $$IcMappingsTableUpdateCompanionBuilder,
      (IcMapping, BaseReferences<_$AppDatabase, $IcMappingsTable, IcMapping>),
      IcMapping,
      PrefetchHooks Function()
    >;
typedef $$IcPositionsTableCreateCompanionBuilder =
    IcPositionsCompanion Function({
      required String icName,
      required double latitude,
      required double longitude,
      Value<int> rowid,
    });
typedef $$IcPositionsTableUpdateCompanionBuilder =
    IcPositionsCompanion Function({
      Value<String> icName,
      Value<double> latitude,
      Value<double> longitude,
      Value<int> rowid,
    });

class $$IcPositionsTableFilterComposer
    extends Composer<_$AppDatabase, $IcPositionsTable> {
  $$IcPositionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get icName => $composableBuilder(
    column: $table.icName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IcPositionsTableOrderingComposer
    extends Composer<_$AppDatabase, $IcPositionsTable> {
  $$IcPositionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get icName => $composableBuilder(
    column: $table.icName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IcPositionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IcPositionsTable> {
  $$IcPositionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get icName =>
      $composableBuilder(column: $table.icName, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);
}

class $$IcPositionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IcPositionsTable,
          IcPosition,
          $$IcPositionsTableFilterComposer,
          $$IcPositionsTableOrderingComposer,
          $$IcPositionsTableAnnotationComposer,
          $$IcPositionsTableCreateCompanionBuilder,
          $$IcPositionsTableUpdateCompanionBuilder,
          (
            IcPosition,
            BaseReferences<_$AppDatabase, $IcPositionsTable, IcPosition>,
          ),
          IcPosition,
          PrefetchHooks Function()
        > {
  $$IcPositionsTableTableManager(_$AppDatabase db, $IcPositionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IcPositionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IcPositionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IcPositionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> icName = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IcPositionsCompanion(
                icName: icName,
                latitude: latitude,
                longitude: longitude,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String icName,
                required double latitude,
                required double longitude,
                Value<int> rowid = const Value.absent(),
              }) => IcPositionsCompanion.insert(
                icName: icName,
                latitude: latitude,
                longitude: longitude,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IcPositionsTable, IcPosition>(table),
                  BaseReferences<_$AppDatabase, $IcPositionsTable, IcPosition>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IcPositionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IcPositionsTable,
      IcPosition,
      $$IcPositionsTableFilterComposer,
      $$IcPositionsTableOrderingComposer,
      $$IcPositionsTableAnnotationComposer,
      $$IcPositionsTableCreateCompanionBuilder,
      $$IcPositionsTableUpdateCompanionBuilder,
      (
        IcPosition,
        BaseReferences<_$AppDatabase, $IcPositionsTable, IcPosition>,
      ),
      IcPosition,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StatementLinesTableTableManager get statementLines =>
      $$StatementLinesTableTableManager(_db, _db.statementLines);
  $$IcMappingsTableTableManager get icMappings =>
      $$IcMappingsTableTableManager(_db, _db.icMappings);
  $$IcPositionsTableTableManager get icPositions =>
      $$IcPositionsTableTableManager(_db, _db.icPositions);
}
