class AppStrings {
  const AppStrings._();

  static const appTitle = 'Top Karta (ТГУ)';

  static const tabFoodZones = 'Зоны еды';
  static const tabNavigation = 'Навигация';
  static const tabRoute = 'Маршрут';
  static const tabTour = 'Тур';
  static const tabTree = 'Дерево';

  static const mapAssetPath = 'assets/map.png';
  static const placesAssetPath = 'assets/places.json';
  static const landmarksAssetPath = 'assets/landmarks.json';

  static const errorLoadMap = 'Не удалось загрузить карту';
  static const searchingRoute = 'Ищем маршрут...';

  static const navAppBarTitle = 'Навигация (A*)';
  static const navSelectFinish = 'Выберите точку финиша';
  static const navAnimationOn = 'Анимация включена';
  static const navAnimationOff = 'Анимация выключена';
  static const navEditMode = 'Режим редактирования';
  static const navNormalMode = 'Обычный режим';
  static const navResetAll = 'Сбросить всё';
  static const navStartLabel = 'Старт';
  static const navFinishLabel = 'Финиш';
  static const navTapForStart = 'Нажмите на карту, чтобы выбрать точку старта';

  static String navRouteFound(
    int distanceMeters,
    int timeMinutes,
    int iterations,
  ) =>
      'Маршрут найден! ~$distanceMetersм, ~$timeMinutes мин\nИтераций A*: $iterations';
  static String navRouteNotFound(int iterations) =>
      'Маршрут не найден!\nИтераций: $iterations';

  static const mealAppBarTitle = 'Маршрут еды (GA)';
  static const mealFoundOptimalRoute = 'Оптимальный маршрут найден!';
  static const mealCalculating = 'Считаем...';
  static const mealFindFood = 'Найти еду';
  static const mealWhatToBuy = 'Что хотите купить?';
  static const mealRouteSheetTitle = 'Машрут покупки';
  static String mealUnavailableNow(String dishes) =>
      'Сейчас недоступно: $dishes';
  static String mealSummary(int placeCount, double minutes) =>
      'Заведений: $placeCount | Оценка: ${minutes.toStringAsFixed(1)} мин';
  static String mealMenuItems(String menu) => 'Меню: $menu';
  static String mealCalculationError(Object error) =>
      'Ошибка расчёта маршрута: $error';

  static const foodZonesTitleEuclidean = 'Зоны еды (Euclidean)';
  static const foodZonesTitleWalking = 'Зоны еды (Walking A*)';
  static const foodZonesByLine = 'По прямой';
  static const foodZonesByPaths = 'По тропам';
  static const foodZonesLegendTitle = 'Зоны питания:';
  static const foodZonesLegendZone1 = 'Зона 1 (Запад)';
  static const foodZonesLegendZone2 = 'Зона 2 (Центр)';
  static const foodZonesLegendZone3 = 'Зона 3 (Восток)';
  static const foodZonesMenuTitle = 'Меню:';
  static String foodZonesChangedCount(int count) => 'Меняют кластер: $count';
  static String foodZonesName(String name) => 'Название: $name';
  static String foodZonesType(String type) => 'Тип: $type';
  static String foodZonesWorkingHours(String openTime, String closeTime) =>
      'Время работы: $openTime - $closeTime';
  static String foodZonesPrices(String level) => 'Цены: $level';
  static String foodZonesDirectCluster(int cluster) =>
      'Кластер (по прямой): $cluster';
  static String foodZonesWalkingCluster(int cluster) =>
      'Кластер (по тропам): $cluster';

  static const tourAppBarTitle = 'Тур по роще (ACO)';
  static const tourLandmarksTitle = 'Достопримечательности';
  static const tourTapStartHint = 'Сначала тапни на карту для выбора старта';
  static const tourBuild = 'Построить тур (муравьи)';
  static const tourStartLabel = 'Старт';
  static const loadingDataErrorPrefix = 'Ошибка загрузки данных: ';
  static String tourIterationProgress(
    int iteration,
    int maxIterations,
    double bestCost,
  ) =>
      'Итерация $iteration/$maxIterations, лучшая оценка: ${bestCost.toStringAsFixed(1)}';
  static String tourRouteFound(int points, double cost) =>
      'Маршрут найден: $points точек, стоимость ${cost.toStringAsFixed(1)}';

  static const decisionTreeTitle = 'Дерево решений (ID3)';
  static const decisionTrainSample = 'Обучающая выборка (CSV)';
  static const decisionCsvHint = 'location,budget,...,recommended_place';
  static const decisionTrainButton = 'Обучить дерево';
  static const decisionRecalcButton = 'Пересчитать';
  static const decisionPruningTitle = 'Сжатие дерева (bonus)';
  static const decisionModeLabel = 'Режим:';
  static const decisionModeFull = 'Полное';
  static const decisionModePruned = 'Сжатое';
  static String decisionMaxPrunedDepth(int depth) =>
      'Макс. глубина сжатого: $depth';
  static const decisionFeaturesTitle = 'Ввод признаков';
  static const decisionResultTitle = 'Результат';
  static String decisionRecommendedPlace(String place) =>
      'Рекомендованное место: $place';
  static const decisionPathTitle = 'Путь по дереву:';
  static const decisionGraphTitle = 'Граф дерева';
  static String decisionFullStats(int nodes, int leaves, int depth) =>
      'Полное: узлов $nodes, листьев $leaves, глубина $depth';
  static String decisionPrunedStats(int nodes, int leaves, int depth) =>
      'Сжатое: узлов $nodes, листьев $leaves, глубина $depth';
  static String decisionNodeReduction(double reduction) =>
      'Сокращение узлов: ${reduction.toStringAsFixed(1)}%';
  static String decisionLeafClass(String label) => 'Класс: $label';
  static String decisionSplitFeature(String feature) => 'Признак: $feature';

  static const astarOutOfBounds = 'Старт или финиш вне карты';
  static const astarFailedSnap = 'Не удалось найти ближайшую проходимую точку';
  static String astarStartSnapped(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) => 'Старт смещен с ($fromRow, $fromCol) на ($toRow, $toCol)';
  static String astarEndSnapped(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) => 'Финиш смещен с ($fromRow, $fromCol) на ($toRow, $toCol)';
  static String astarPathFound(int iterations) =>
      'Путь найден за $iterations итераций!';
  static String astarPathNotFound(int iterations) =>
      'Путь не найден! Пройдено итераций: $iterations';
}
