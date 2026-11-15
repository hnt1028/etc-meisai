// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _vehicleTypeMeta = const VerificationMeta(
    'vehicleType',
  );
  @override
  late final GeneratedColumn<String> vehicleType = GeneratedColumn<String>(
    'vehicle_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vehicleNumberMeta = const VerificationMeta(
    'vehicleNumber',
  );
  @override
  late final GeneratedColumn<String> vehicleNumber = GeneratedColumn<String>(
    'vehicle_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<ConfirmationStatusValue, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ConfirmationStatusValue>($TripsTable.$converterstatus);
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
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
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
    if (data.containsKey('vehicle_type')) {
      context.handle(
        _vehicleTypeMeta,
        vehicleType.isAcceptableOrUnknown(
          data['vehicle_type']!,
          _vehicleTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vehicleTypeMeta);
    }
    if (data.containsKey('vehicle_number')) {
      context.handle(
        _vehicleNumberMeta,
        vehicleNumber.isAcceptableOrUnknown(
          data['vehicle_number']!,
          _vehicleNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vehicleNumberMeta);
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
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
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
      vehicleType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_type'],
      )!,
      vehicleNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_number'],
      )!,
      cardNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_number'],
      )!,
      status: $TripsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
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
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ConfirmationStatusValue, String, String>
  $converterstatus = const EnumNameConverter<ConfirmationStatusValue>(
    ConfirmationStatusValue.values,
  );
}

class Trip extends DataClass implements Insertable<Trip> {
  final int id;

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
  final String vehicleType;
  final String vehicleNumber;
  final String cardNumber;
  final ConfirmationStatusValue status;

  /// Discount types joined with `;`, like the CSV note. Empty when none.
  final String discountTypes;
  const Trip({
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
    required this.vehicleNumber,
    required this.cardNumber,
    required this.status,
    required this.discountTypes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
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
    map['vehicle_type'] = Variable<String>(vehicleType);
    map['vehicle_number'] = Variable<String>(vehicleNumber);
    map['card_number'] = Variable<String>(cardNumber);
    {
      map['status'] = Variable<String>(
        $TripsTable.$converterstatus.toSql(status),
      );
    }
    map['discount_types'] = Variable<String>(discountTypes);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
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
      vehicleNumber: Value(vehicleNumber),
      cardNumber: Value(cardNumber),
      status: Value(status),
      discountTypes: Value(discountTypes),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      id: serializer.fromJson<int>(json['id']),
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
      vehicleType: serializer.fromJson<String>(json['vehicleType']),
      vehicleNumber: serializer.fromJson<String>(json['vehicleNumber']),
      cardNumber: serializer.fromJson<String>(json['cardNumber']),
      status: $TripsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      discountTypes: serializer.fromJson<String>(json['discountTypes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
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
      'vehicleType': serializer.toJson<String>(vehicleType),
      'vehicleNumber': serializer.toJson<String>(vehicleNumber),
      'cardNumber': serializer.toJson<String>(cardNumber),
      'status': serializer.toJson<String>(
        $TripsTable.$converterstatus.toJson(status),
      ),
      'discountTypes': serializer.toJson<String>(discountTypes),
    };
  }

  Trip copyWith({
    int? id,
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
    String? vehicleType,
    String? vehicleNumber,
    String? cardNumber,
    ConfirmationStatusValue? status,
    String? discountTypes,
  }) => Trip(
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
    vehicleNumber: vehicleNumber ?? this.vehicleNumber,
    cardNumber: cardNumber ?? this.cardNumber,
    status: status ?? this.status,
    discountTypes: discountTypes ?? this.discountTypes,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
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
    return (StringBuffer('Trip(')
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
      (other is Trip &&
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

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<int> id;
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
  final Value<String> vehicleType;
  final Value<String> vehicleNumber;
  final Value<String> cardNumber;
  final Value<ConfirmationStatusValue> status;
  final Value<String> discountTypes;
  const TripsCompanion({
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
  });
  TripsCompanion.insert({
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
    required String vehicleType,
    required String vehicleNumber,
    required String cardNumber,
    required ConfirmationStatusValue status,
    required String discountTypes,
  }) : duplicateKey = Value(duplicateKey),
       exitAt = Value(exitAt),
       exitIc = Value(exitIc),
       fare = Value(fare),
       fareAfterRebate = Value(fareAfterRebate),
       postpaidFare = Value(postpaidFare),
       vehicleType = Value(vehicleType),
       vehicleNumber = Value(vehicleNumber),
       cardNumber = Value(cardNumber),
       status = Value(status),
       discountTypes = Value(discountTypes);
  static Insertable<Trip> custom({
    Expression<int>? id,
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
    Expression<String>? vehicleType,
    Expression<String>? vehicleNumber,
    Expression<String>? cardNumber,
    Expression<String>? status,
    Expression<String>? discountTypes,
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
    });
  }

  TripsCompanion copyWith({
    Value<int>? id,
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
    Value<String>? vehicleType,
    Value<String>? vehicleNumber,
    Value<String>? cardNumber,
    Value<ConfirmationStatusValue>? status,
    Value<String>? discountTypes,
  }) {
    return TripsCompanion(
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
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
      map['vehicle_type'] = Variable<String>(vehicleType.value);
    }
    if (vehicleNumber.present) {
      map['vehicle_number'] = Variable<String>(vehicleNumber.value);
    }
    if (cardNumber.present) {
      map['card_number'] = Variable<String>(cardNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $TripsTable.$converterstatus.toSql(status.value),
      );
    }
    if (discountTypes.present) {
      map['discount_types'] = Variable<String>(discountTypes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
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
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TripsTable trips = $TripsTable(this);
  late final Index tripsExitAt = Index(
    'trips_exit_at',
    'CREATE INDEX trips_exit_at ON trips (exit_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [trips, tripsExitAt];
}

typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
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
      required String vehicleType,
      required String vehicleNumber,
      required String cardNumber,
      required ConfirmationStatusValue status,
      required String discountTypes,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<int> id,
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
      Value<String> vehicleType,
      Value<String> vehicleNumber,
      Value<String> cardNumber,
      Value<ConfirmationStatusValue> status,
      Value<String> discountTypes,
    });

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
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

  ColumnFilters<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vehicleNumber => $composableBuilder(
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
    String
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

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
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

  ColumnOrderings<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vehicleNumber => $composableBuilder(
    column: $table.vehicleNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardNumber => $composableBuilder(
    column: $table.cardNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountTypes => $composableBuilder(
    column: $table.discountTypes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
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

  GeneratedColumn<String> get vehicleType => $composableBuilder(
    column: $table.vehicleType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vehicleNumber => $composableBuilder(
    column: $table.vehicleNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardNumber => $composableBuilder(
    column: $table.cardNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ConfirmationStatusValue, String>
  get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get discountTypes => $composableBuilder(
    column: $table.discountTypes,
    builder: (column) => column,
  );
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, BaseReferences<_$AppDatabase, $TripsTable, Trip>),
          Trip,
          PrefetchHooks Function()
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
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
                Value<String> vehicleType = const Value.absent(),
                Value<String> vehicleNumber = const Value.absent(),
                Value<String> cardNumber = const Value.absent(),
                Value<ConfirmationStatusValue> status = const Value.absent(),
                Value<String> discountTypes = const Value.absent(),
              }) => TripsCompanion(
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
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
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
                required String vehicleType,
                required String vehicleNumber,
                required String cardNumber,
                required ConfirmationStatusValue status,
                required String discountTypes,
              }) => TripsCompanion.insert(
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
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TripsTable, Trip>(table),
                  BaseReferences<_$AppDatabase, $TripsTable, Trip>(
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

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, BaseReferences<_$AppDatabase, $TripsTable, Trip>),
      Trip,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
}
