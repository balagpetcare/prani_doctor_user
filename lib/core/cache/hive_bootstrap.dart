import 'package:hive_flutter/hive_flutter.dart';

const kAppCacheBoxName = 'app_cache';

Future<void> initHiveCache() async {
  await Hive.initFlutter();
  if (!Hive.isBoxOpen(kAppCacheBoxName)) {
    await Hive.openBox<dynamic>(kAppCacheBoxName);
  }
}

Box<dynamic> openCacheBox() => Hive.box<dynamic>(kAppCacheBoxName);
