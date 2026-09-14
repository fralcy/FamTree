import 'package:hive_flutter/hive_flutter.dart';

import '../../models/index.dart';

/// Singleton duy nhất chạm vào Hive trong toàn app. UI/Provider không bao
/// giờ gọi thẳng `Hive.*` — luôn qua [DataManager].
class DataManager {
  DataManager._();

  static final DataManager _instance = DataManager._();

  factory DataManager() => _instance;

  bool _initialized = false;

  late Box<FamilyTree> _familyTreeBox;
  late Box<Person> _personBox;
  late Box<Relationship> _relationshipBox;
  late Box _settingsBox;

  static const String _themeIdKey = 'themeId';
  static const String _languageCodeKey = 'languageCode';
  static const String defaultThemeId = 'default';
  static const String defaultLanguageCode = 'vi';

  /// Idempotent — an toàn gọi lại nhiều lần (hot restart, nhiều test setUp).
  /// [hivePath] chỉ dùng cho test (`Hive.init(dir)` thay vì `initFlutter()`).
  Future<void> initialize({String? hivePath}) async {
    if (_initialized) return;

    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(FamilyTreeAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PersonAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(RelationshipAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(GenderAdapter());
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(RelationshipTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ChildTypeAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(LunarDateAdapter());

    _familyTreeBox = await Hive.openBox<FamilyTree>('family_trees');
    _personBox = await Hive.openBox<Person>('persons');
    _relationshipBox = await Hive.openBox<Relationship>('relationships');
    _settingsBox = await Hive.openBox('settings');

    _initialized = true;
  }

  // ---- FamilyTree ----

  List<FamilyTree> getAllFamilyTrees() => _familyTreeBox.values.toList();

  FamilyTree? getFamilyTree(String id) => _familyTreeBox.get(id);

  Future<void> saveFamilyTree(FamilyTree tree) => _familyTreeBox.put(tree.id, tree);

  /// Xoá 1 cây kèm cascade toàn bộ Person/Relationship cùng familyTreeId.
  Future<void> deleteFamilyTree(String id) async {
    final personIds = _personBox.values
        .where((p) => p.familyTreeId == id)
        .map((p) => p.id)
        .toList();
    final relationshipIds = _relationshipBox.values
        .where((r) => r.familyTreeId == id)
        .map((r) => r.id)
        .toList();
    await _relationshipBox.deleteAll(relationshipIds);
    await _personBox.deleteAll(personIds);
    await _familyTreeBox.delete(id);
  }

  // ---- Person ----

  List<Person> getPersonsByTree(String familyTreeId) =>
      _personBox.values.where((p) => p.familyTreeId == familyTreeId).toList();

  Person? getPerson(String id) => _personBox.get(id);

  Future<void> savePerson(Person person) => _personBox.put(person.id, person);

  /// Xoá 1 Person kèm cascade mọi Relationship có personAId/personBId == id
  /// đó, tránh rác dữ liệu treo. KHÔNG cascade sang parentChild của người
  /// khác (con vẫn giữ nguyên liên kết với cha/mẹ còn lại).
  Future<void> deletePerson(String id) async {
    final relationshipIds = _relationshipBox.values
        .where((r) => r.personAId == id || r.personBId == id)
        .map((r) => r.id)
        .toList();
    await _relationshipBox.deleteAll(relationshipIds);
    await _personBox.delete(id);
  }

  // ---- Relationship ----

  List<Relationship> getRelationshipsByTree(String familyTreeId) =>
      _relationshipBox.values.where((r) => r.familyTreeId == familyTreeId).toList();

  Future<void> saveRelationship(Relationship relationship) =>
      _relationshipBox.put(relationship.id, relationship);

  Future<void> deleteRelationship(String id) => _relationshipBox.delete(id);

  // ---- Settings ----

  String getThemeId() => (_settingsBox.get(_themeIdKey) as String?) ?? defaultThemeId;

  Future<void> saveThemeId(String id) => _settingsBox.put(_themeIdKey, id);

  String getLanguageCode() =>
      (_settingsBox.get(_languageCodeKey) as String?) ?? defaultLanguageCode;

  Future<void> saveLanguageCode(String code) => _settingsBox.put(_languageCodeKey, code);
}
