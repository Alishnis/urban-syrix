import 'package:flutter/widgets.dart';
import 'package:hackathon_net/core/localization/app_language.dart';
import 'package:hackathon_net/core/localization/language_scope.dart';
import 'package:hackathon_net/domain/models/urban_models.dart';

class AppLocalizations {
  AppLocalizations(this.language);

  final AppLanguage language;

  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(LanguageScope.of(context).language);
  }

  static const _strings = <String, Map<AppLanguage, String>>{
    'dashboard': {
      AppLanguage.en: 'Dashboard',
      AppLanguage.ru: 'Дашборд',
      AppLanguage.kk: 'Бақылау',
    },
    'map': {
      AppLanguage.en: 'Map',
      AppLanguage.ru: 'Карта',
      AppLanguage.kk: 'Карта',
    },
    'account': {
      AppLanguage.en: 'Account',
      AppLanguage.ru: 'Аккаунт',
      AppLanguage.kk: 'Аккаунт',
    },
    'swipe_reviews': {
      AppLanguage.en: 'Swipe reviews',
      AppLanguage.ru: 'Свайп-отзывы',
      AppLanguage.kk: 'Свайп-пікірлер',
    },
    'swipe_reviews_title': {
      AppLanguage.en: 'Rate organizations with a swipe.',
      AppLanguage.ru: 'Оценивайте организации свайпом.',
      AppLanguage.kk: 'Ұйымдарды свайп арқылы бағалаңыз.',
    },
    'swipe_reviews_body': {
      AppLanguage.en:
          'Swipe right if you like the organization and left if you do not. Every swipe opens a review form for detailed feedback.',
      AppLanguage.ru:
          'Свайп вправо, если организация вам понравилась, и влево, если нет. После каждого свайпа открывается форма отзыва.',
      AppLanguage.kk:
          'Ұйым ұнаса оңға, ұнамаса солға свайп жасаңыз. Әр свайптан кейін пікір формасы ашылады.',
    },
    'swipe_left': {
      AppLanguage.en: 'Swipe left',
      AppLanguage.ru: 'Свайп влево',
      AppLanguage.kk: 'Солға свайп',
    },
    'swipe_right': {
      AppLanguage.en: 'Swipe right',
      AppLanguage.ru: 'Свайп вправо',
      AppLanguage.kk: 'Оңға свайп',
    },
    'remaining_places': {
      AppLanguage.en: 'Places left',
      AppLanguage.ru: 'Осталось мест',
      AppLanguage.kk: 'Қалған орындар',
    },
    'swipe_done_title': {
      AppLanguage.en: 'Deck completed',
      AppLanguage.ru: 'Карточки закончились',
      AppLanguage.kk: 'Карточкалар аяқталды',
    },
    'swipe_done_subtitle': {
      AppLanguage.en: 'You have reviewed every available organization.',
      AppLanguage.ru: 'Вы уже оценили все доступные организации.',
      AppLanguage.kk: 'Қолжетімді ұйымдардың барлығын бағаладыңыз.',
    },
    'reload_deck': {
      AppLanguage.en: 'Reload deck',
      AppLanguage.ru: 'Обновить карточки',
      AppLanguage.kk: 'Карточкаларды жаңарту',
    },
    'retry': {
      AppLanguage.en: 'Retry',
      AppLanguage.ru: 'Повторить',
      AppLanguage.kk: 'Қайта көру',
    },
    'swipe_load_failed': {
      AppLanguage.en: 'Failed to load swipe deck.',
      AppLanguage.ru: 'Не удалось загрузить карточки.',
      AppLanguage.kk: 'Свайп карточкаларын жүктеу сәтсіз.',
    },
    'review_dialog_like_title': {
      AppLanguage.en: 'You swiped right - share your positive experience',
      AppLanguage.ru: 'Вы свайпнули вправо - поделитесь положительным опытом',
      AppLanguage.kk: 'Оңға свайп жасадыңыз - оң тәжірибеңізбен бөлісіңіз',
    },
    'review_dialog_dislike_title': {
      AppLanguage.en: 'You swiped left - share what should improve',
      AppLanguage.ru: 'Вы свайпнули влево - расскажите, что нужно улучшить',
      AppLanguage.kk: 'Солға свайп жасадыңыз - не жақсарту керегін жазыңыз',
    },
    'experience_summary': {
      AppLanguage.en: 'Experience summary',
      AppLanguage.ru: 'Краткое резюме опыта',
      AppLanguage.kk: 'Тәжірибе қысқаша мазмұны',
    },
    'experience_details': {
      AppLanguage.en: 'Detailed feedback',
      AppLanguage.ru: 'Подробный отзыв',
      AppLanguage.kk: 'Толық пікір',
    },
    'summary_validation': {
      AppLanguage.en: 'Summary must be at least 8 characters.',
      AppLanguage.ru: 'Краткое описание должно быть не короче 8 символов.',
      AppLanguage.kk: 'Қысқаша сипаттама кемінде 8 таңба болуы керек.',
    },
    'details_validation': {
      AppLanguage.en: 'Details must be at least 16 characters.',
      AppLanguage.ru: 'Подробности должны быть не короче 16 символов.',
      AppLanguage.kk: 'Толық пікір кемінде 16 таңба болуы керек.',
    },
    'rating': {
      AppLanguage.en: 'Rating',
      AppLanguage.ru: 'Оценка',
      AppLanguage.kk: 'Баға',
    },
    'attach_media': {
      AppLanguage.en: 'Attach images/videos',
      AppLanguage.ru: 'Прикрепить фото/видео',
      AppLanguage.kk: 'Фото/видео тіркеу',
    },
    'submit_review': {
      AppLanguage.en: 'Submit review',
      AppLanguage.ru: 'Отправить отзыв',
      AppLanguage.kk: 'Пікір жіберу',
    },
    'review_submitted_admin': {
      AppLanguage.en: 'Review submitted for administrator moderation.',
      AppLanguage.ru: 'Отзыв отправлен на модерацию администратору.',
      AppLanguage.kk: 'Пікір әкімші модерациясына жіберілді.',
    },
    'review_submit_failed': {
      AppLanguage.en: 'Failed to submit review.',
      AppLanguage.ru: 'Не удалось отправить отзыв.',
      AppLanguage.kk: 'Пікірді жіберу сәтсіз.',
    },
    'reward_progress': {
      AppLanguage.en: 'Reward progress',
      AppLanguage.ru: 'Прогресс награды',
      AppLanguage.kk: 'Сыйлық прогресі',
    },
    'approved_reviews': {
      AppLanguage.en: 'Approved reviews',
      AppLanguage.ru: 'Одобренные отзывы',
      AppLanguage.kk: 'Мақұлданған пікірлер',
    },
    'current_milestone': {
      AppLanguage.en: 'Milestone',
      AppLanguage.ru: 'Этап',
      AppLanguage.kk: 'Кезең',
    },
    'next_reward_at': {
      AppLanguage.en: 'Next gift card at',
      AppLanguage.ru: 'Следующая подарочная карта на',
      AppLanguage.kk: 'Келесі сыйлық картасы',
    },
    'reviews_left': {
      AppLanguage.en: 'Reviews left',
      AppLanguage.ru: 'Осталось отзывов',
      AppLanguage.kk: 'Қалған пікір',
    },
    'moderation_queue': {
      AppLanguage.en: 'Moderation queue',
      AppLanguage.ru: 'Очередь модерации',
      AppLanguage.kk: 'Модерация кезегі',
    },
    'moderation_load_failed': {
      AppLanguage.en: 'Failed to load moderation queue.',
      AppLanguage.ru: 'Не удалось загрузить очередь модерации.',
      AppLanguage.kk: 'Модерация кезегін жүктеу сәтсіз.',
    },
    'moderation_queue_empty': {
      AppLanguage.en: 'No pending reviews',
      AppLanguage.ru: 'Нет отзывов в ожидании',
      AppLanguage.kk: 'Күтіп тұрған пікір жоқ',
    },
    'moderation_queue_empty_body': {
      AppLanguage.en: 'All pending reviews are already processed.',
      AppLanguage.ru: 'Все отзывы из очереди уже обработаны.',
      AppLanguage.kk: 'Кезектегі барлық пікір өңделді.',
    },
    'approve': {
      AppLanguage.en: 'Approve',
      AppLanguage.ru: 'Одобрить',
      AppLanguage.kk: 'Мақұлдау',
    },
    'reject': {
      AppLanguage.en: 'Reject',
      AppLanguage.ru: 'Отклонить',
      AppLanguage.kk: 'Қабылдамау',
    },
    'moderation_reason': {
      AppLanguage.en: 'Moderation reason',
      AppLanguage.ru: 'Причина модерации',
      AppLanguage.kk: 'Модерация себебі',
    },
    'save': {
      AppLanguage.en: 'Save',
      AppLanguage.ru: 'Сохранить',
      AppLanguage.kk: 'Сақтау',
    },
    'close': {
      AppLanguage.en: 'Close',
      AppLanguage.ru: 'Закрыть',
      AppLanguage.kk: 'Жабу',
    },
    'attached_media': {
      AppLanguage.en: 'Attached media',
      AppLanguage.ru: 'Прикреплённое медиа',
      AppLanguage.kk: 'Тіркелген медиа',
    },
    'structural_glass_mode': {
      AppLanguage.en: 'STRUCTURAL GLASS MODE',
      AppLanguage.ru: 'РЕЖИМ STRUCTURAL GLASS',
      AppLanguage.kk: 'STRUCTURAL GLASS РЕЖИМІ',
    },
    'live_city_map': {
      AppLanguage.en: 'Live city map',
      AppLanguage.ru: 'Живая карта города',
      AppLanguage.kk: 'Тікелей қала картасы',
    },
    'map_metric_hint': {
      AppLanguage.en: 'Tap anywhere on the map to add a marker.',
      AppLanguage.ru: 'Нажмите в любую точку карты, чтобы добавить метку.',
      AppLanguage.kk: 'Белгі қосу үшін картаның кез келген жерін басыңыз.',
    },
    'tap_to_add_place': {
      AppLanguage.en: 'Tap the map to add a building or infrastructure point.',
      AppLanguage.ru:
          'Нажмите на карту, чтобы добавить здание или инфраструктурную точку.',
      AppLanguage.kk:
          'Ғимарат немесе инфрақұрылым нүктесін қосу үшін картаны басыңыз.',
    },
    'tap_to_add_accident': {
      AppLanguage.en:
          'Tap the map to place an accident marker and open detection flow.',
      AppLanguage.ru:
          'Нажмите на карту, чтобы поставить аварийную метку и открыть detection flow.',
      AppLanguage.kk:
          'Апат белгісін қою және detection flow ашу үшін картаны басыңыз.',
    },
    'tap_to_set_start': {
      AppLanguage.en: 'Tap the map to set the route start point.',
      AppLanguage.ru: 'Нажмите на карту, чтобы задать старт маршрута.',
      AppLanguage.kk: 'Маршруттың басталу нүктесін қою үшін картаны басыңыз.',
    },
    'tap_to_set_destination': {
      AppLanguage.en: 'Tap the map to set the route destination.',
      AppLanguage.ru: 'Нажмите на карту, чтобы задать точку назначения.',
      AppLanguage.kk: 'Маршруттың соңғы нүктесін қою үшін картаны басыңыз.',
    },
    'pick_create_mode': {
      AppLanguage.en: 'Choose Add place or Add accident first.',
      AppLanguage.ru: 'Сначала выберите Add place или Add accident.',
      AppLanguage.kk: 'Алдымен Add place немесе Add accident таңдаңыз.',
    },
    'add_place': {
      AppLanguage.en: 'Add place',
      AppLanguage.ru: 'Добавить объект',
      AppLanguage.kk: 'Нысан қосу',
    },
    'add_accident': {
      AppLanguage.en: 'Add accident',
      AppLanguage.ru: 'Добавить аварию',
      AppLanguage.kk: 'Апат қосу',
    },
    'set_start': {
      AppLanguage.en: 'Set start',
      AppLanguage.ru: 'Точка старта',
      AppLanguage.kk: 'Бастау нүктесі',
    },
    'set_destination': {
      AppLanguage.en: 'Set end',
      AppLanguage.ru: 'Точка финиша',
      AppLanguage.kk: 'Аяқтау нүктесі',
    },
    'build_safe_route': {
      AppLanguage.en: 'Build safe route',
      AppLanguage.ru: 'Построить безопасный маршрут',
      AppLanguage.kk: 'Қауіпсіз маршрут құру',
    },
    'building_route': {
      AppLanguage.en: 'Building route...',
      AppLanguage.ru: 'Маршрут строится...',
      AppLanguage.kk: 'Маршрут құрылуда...',
    },
    'clear_route': {
      AppLanguage.en: 'Clear route',
      AppLanguage.ru: 'Очистить маршрут',
      AppLanguage.kk: 'Маршрутты тазалау',
    },
    'safe_route_ready': {
      AppLanguage.en: 'Safe route ready:',
      AppLanguage.ru: 'Безопасный маршрут готов:',
      AppLanguage.kk: 'Қауіпсіз маршрут дайын:',
    },
    'accidents_avoided': {
      AppLanguage.en: 'incidents avoided',
      AppLanguage.ru: 'инцидентов в обходе',
      AppLanguage.kk: 'инцидент айналып өтілді',
    },
    'route_start': {
      AppLanguage.en: 'Route start',
      AppLanguage.ru: 'Старт маршрута',
      AppLanguage.kk: 'Маршрут бастауы',
    },
    'route_destination': {
      AppLanguage.en: 'Route destination',
      AppLanguage.ru: 'Точка назначения',
      AppLanguage.kk: 'Маршрут мақсаты',
    },
    'cloud_syncing': {
      AppLanguage.en: 'Syncing map points with cloud storage...',
      AppLanguage.ru: 'Синхронизация точек карты с облаком...',
      AppLanguage.kk: 'Карта нүктелері бұлтпен синхрондалуда...',
    },
    'cloud_sync_failed': {
      AppLanguage.en:
          'Cloud sync failed. Run the urban_places.sql script in Supabase and verify table policies.',
      AppLanguage.ru:
          'Синхронизация с облаком не удалась. Выполните urban_places.sql в Supabase и проверьте политики таблицы.',
      AppLanguage.kk:
          'Бұлтпен синхрондау сәтсіз. Supabase ішінде urban_places.sql скриптін орындап, кесте саясаттарын тексеріңіз.',
    },
    'new_marker_location': {
      AppLanguage.en: 'New marker location',
      AppLanguage.ru: 'Новая точка метки',
      AppLanguage.kk: 'Жаңа белгі орны',
    },
    'selected_point': {
      AppLanguage.en: 'Selected point',
      AppLanguage.ru: 'Выбранная точка',
      AppLanguage.kk: 'Таңдалған нүкте',
    },
    'create_map_point': {
      AppLanguage.en: 'Create map point',
      AppLanguage.ru: 'Создать точку на карте',
      AppLanguage.kk: 'Карта нүктесін құру',
    },
    'add_city_signal': {
      AppLanguage.en: 'Add a new city signal directly from the map.',
      AppLanguage.ru: 'Добавьте новый городской сигнал прямо с карты.',
      AppLanguage.kk: 'Қалалық жаңа сигналды картадан тікелей қосыңыз.',
    },
    'coordinates': {
      AppLanguage.en: 'Coordinates',
      AppLanguage.ru: 'Координаты',
      AppLanguage.kk: 'Координаттар',
    },
    'openai_enabled': {
      AppLanguage.en:
          'Description and category scores will be processed by OpenAI.',
      AppLanguage.ru:
          'Описание и оценки по категориям будут обработаны через OpenAI.',
      AppLanguage.kk: 'Сипаттама мен санат бағалары OpenAI арқылы өңделеді.',
    },
    'openai_disabled': {
      AppLanguage.en:
          'OpenAI scoring is disabled. Add OPENAI_API_KEY through --dart-define to enable AI analysis.',
      AppLanguage.ru:
          'OpenAI scoring отключён. Добавьте OPENAI_API_KEY через --dart-define.',
      AppLanguage.kk:
          'OpenAI scoring өшірулі. OPENAI_API_KEY параметрін --dart-define арқылы беріңіз.',
    },
    'name': {
      AppLanguage.en: 'Name',
      AppLanguage.ru: 'Название',
      AppLanguage.kk: 'Атауы',
    },
    'type': {
      AppLanguage.en: 'Type',
      AppLanguage.ru: 'Тип',
      AppLanguage.kk: 'Түрі',
    },
    'description': {
      AppLanguage.en: 'Description',
      AppLanguage.ru: 'Описание',
      AppLanguage.kk: 'Сипаттама',
    },
    'address': {
      AppLanguage.en: 'Address',
      AppLanguage.ru: 'Адрес',
      AppLanguage.kk: 'Мекенжай',
    },
    'enter_name': {
      AppLanguage.en: 'Enter a name.',
      AppLanguage.ru: 'Введите название.',
      AppLanguage.kk: 'Атауын енгізіңіз.',
    },
    'enter_description': {
      AppLanguage.en: 'Enter a description.',
      AppLanguage.ru: 'Введите описание.',
      AppLanguage.kk: 'Сипаттаманы енгізіңіз.',
    },
    'enter_address': {
      AppLanguage.en: 'Enter an address.',
      AppLanguage.ru: 'Введите адрес.',
      AppLanguage.kk: 'Мекенжайды енгізіңіз.',
    },
    'address_lookup_failed': {
      AppLanguage.en: 'Address lookup failed. You can edit it manually.',
      AppLanguage.ru: 'Не удалось определить адрес. Можно исправить вручную.',
      AppLanguage.kk: 'Мекенжай табылмады. Қолмен түзете аласыз.',
    },
    'ai_failed': {
      AppLanguage.en:
          'OpenAI analysis failed. Falling back to default scoring for this point.',
      AppLanguage.ru:
          'OpenAI analysis не сработал. Используются базовые оценки.',
      AppLanguage.kk: 'OpenAI талдауы сәтсіз болды. Әдепкі бағалар қолданылды.',
    },
    'save_point_failed': {
      AppLanguage.en:
          'Saving to Supabase failed. Check cloud table setup and try again.',
      AppLanguage.ru:
          'Не удалось сохранить в Supabase. Проверьте настройку таблицы и повторите попытку.',
      AppLanguage.kk:
          'Supabase ішіне сақтау сәтсіз. Кесте баптауын тексеріп, қайта көріңіз.',
    },
    'construction_builder_only': {
      AppLanguage.en:
          'Construction reports can only be created by builder or admin accounts.',
      AppLanguage.ru:
          'Сообщения о стройках могут создавать только аккаунты builder или admin.',
      AppLanguage.kk:
          'Құрылыс туралы хабарламаларды тек builder немесе admin аккаунттары жасай алады.',
    },
    'map_point_builder_only': {
      AppLanguage.en: 'Only builder or admin accounts can create map points.',
      AppLanguage.ru:
          'Создавать точки на карте могут только аккаунты builder или admin.',
      AppLanguage.kk:
          'Карта нүктелерін тек builder немесе admin аккаунттары құра алады.',
    },
    'auto_start_metrics': {
      AppLanguage.en: 'Auto-start metrics',
      AppLanguage.ru: 'Стартовые метрики',
      AppLanguage.kk: 'Бастапқы метрикалар',
    },
    'auto_start_metrics_body': {
      AppLanguage.en:
          'This new point will start with default score bands and join district scoring immediately.',
      AppLanguage.ru:
          'Новая точка стартует с базовыми оценками и сразу войдёт в расчёт района.',
      AppLanguage.kk:
          'Жаңа нүкте әдепкі бағалармен басталып, аудандық есепке бірден қосылады.',
    },
    'cancel': {
      AppLanguage.en: 'Cancel',
      AppLanguage.ru: 'Отмена',
      AppLanguage.kk: 'Бас тарту',
    },
    'add_point': {
      AppLanguage.en: 'Add point',
      AppLanguage.ru: 'Добавить точку',
      AppLanguage.kk: 'Нүкте қосу',
    },
    'adding': {
      AppLanguage.en: 'Adding...',
      AppLanguage.ru: 'Добавление...',
      AppLanguage.kk: 'Қосылуда...',
    },
    'building': {
      AppLanguage.en: 'Building',
      AppLanguage.ru: 'Здание',
      AppLanguage.kk: 'Ғимарат',
    },
    'construction': {
      AppLanguage.en: 'Construction',
      AppLanguage.ru: 'Стройка',
      AppLanguage.kk: 'Құрылыс',
    },
    'road': {
      AppLanguage.en: 'Road',
      AppLanguage.ru: 'Дорога',
      AppLanguage.kk: 'Жол',
    },
    'incident': {
      AppLanguage.en: 'Incident',
      AppLanguage.ru: 'Инцидент',
      AppLanguage.kk: 'Оқиға',
    },
    'incident_fire': {
      AppLanguage.en: 'Fire',
      AppLanguage.ru: 'Пожар',
      AppLanguage.kk: 'Өрт',
    },
    'incident_car_accident': {
      AppLanguage.en: 'Car accident',
      AppLanguage.ru: 'ДТП',
      AppLanguage.kk: 'Жол апаты',
    },
    'incident_other': {
      AppLanguage.en: 'Other',
      AppLanguage.ru: 'Другое',
      AppLanguage.kk: 'Басқа',
    },
    'incident_detection_title': {
      AppLanguage.en: 'Incident analysis mode',
      AppLanguage.ru: 'Режим анализа инцидента',
      AppLanguage.kk: 'Инцидентті талдау режимі',
    },
    'incident_detection_subtitle': {
      AppLanguage.en:
          'Choose the flow ported from city.mgr: fire detection, car accident detection, or manual report.',
      AppLanguage.ru:
          'Выберите сценарий из city.mgr: детекция пожара, детекция ДТП или ручной отчёт.',
      AppLanguage.kk:
          'city.mgr жобасынан тасымалданған сценарийді таңдаңыз: өрт, жол апаты немесе қолмен есеп.',
    },
    'fire_model_desc': {
      AppLanguage.en:
          'Use the YOLOv8 fire workflow for fire-related incidents.',
      AppLanguage.ru: 'Использует сценарий YOLOv8 для инцидентов с огнём.',
      AppLanguage.kk:
          'Өртке қатысты инциденттер үшін YOLOv8 сценарийі қолданылады.',
    },
    'car_accident_model_desc': {
      AppLanguage.en:
          'Use the YOLOv8 traffic accident workflow for crash events.',
      AppLanguage.ru:
          'Использует сценарий YOLOv8 для дорожно-транспортных происшествий.',
      AppLanguage.kk: 'Жол-көлік оқиғалары үшін YOLOv8 сценарийі қолданылады.',
    },
    'other_model_desc': {
      AppLanguage.en:
          'Create a manual incident report without AI detection media.',
      AppLanguage.ru: 'Создаёт ручной отчёт об инциденте без медиа-детекции.',
      AppLanguage.kk: 'AI-медиа анықтаусыз қолмен инцидент есебін жасайды.',
    },
    'upload_media': {
      AppLanguage.en: 'Upload image or video',
      AppLanguage.ru: 'Загрузить фото или видео',
      AppLanguage.kk: 'Фото немесе видео жүктеу',
    },
    'sensitivity': {
      AppLanguage.en: 'Sensitivity',
      AppLanguage.ru: 'Чувствительность',
      AppLanguage.kk: 'Сезімталдық',
    },
    'analyze_media': {
      AppLanguage.en: 'Analyze media',
      AppLanguage.ru: 'Анализировать медиа',
      AppLanguage.kk: 'Медианы талдау',
    },
    'analyzing': {
      AppLanguage.en: 'Analyzing...',
      AppLanguage.ru: 'Анализ...',
      AppLanguage.kk: 'Талдау...',
    },
    'detection_found': {
      AppLanguage.en: 'Detection found:',
      AppLanguage.ru: 'Обнаружение найдено:',
      AppLanguage.kk: 'Анықтау табылды:',
    },
    'detection_not_found': {
      AppLanguage.en: 'No incident detected in the uploaded media.',
      AppLanguage.ru: 'В загруженном медиа инцидент не найден.',
      AppLanguage.kk: 'Жүктелген медиадан инцидент табылмады.',
    },
    'detection_location': {
      AppLanguage.en: 'Detected area',
      AppLanguage.ru: 'Область обнаружения',
      AppLanguage.kk: 'Анықталған аймақ',
    },
    'detection_coordinates': {
      AppLanguage.en: 'Bounding box',
      AppLanguage.ru: 'Координаты рамки',
      AppLanguage.kk: 'Жақтау координаттары',
    },
    'incident_summary': {
      AppLanguage.en: 'Incident summary',
      AppLanguage.ru: 'Сводка инцидента',
      AppLanguage.kk: 'Инцидент жиынтығы',
    },
    'detected_event': {
      AppLanguage.en: 'Detected event',
      AppLanguage.ru: 'Обнаруженное событие',
      AppLanguage.kk: 'Анықталған оқиға',
    },
    'detection_model': {
      AppLanguage.en: 'Detection model',
      AppLanguage.ru: 'Модель детекции',
      AppLanguage.kk: 'Анықтау моделі',
    },
    'detection_preview': {
      AppLanguage.en: 'Detected area in media',
      AppLanguage.ru: 'Где обнаружено на медиа',
      AppLanguage.kk: 'Медиада қай жерде анықталды',
    },
    'preview_unavailable': {
      AppLanguage.en: 'Detection preview is unavailable.',
      AppLanguage.ru: 'Превью детекции недоступно.',
      AppLanguage.kk: 'Детекция превьюі қолжетімсіз.',
    },
    'incident_description_only': {
      AppLanguage.en:
          'Incidents are shown as live alerts and do not use urban score breakdown.',
      AppLanguage.ru:
          'Инциденты показываются как live alerts и не используют разбивку городского score.',
      AppLanguage.kk:
          'Инциденттер live alert ретінде көрсетіледі және қалалық score бөлінісін қолданбайды.',
    },
    'live_incident': {
      AppLanguage.en: 'Live incident',
      AppLanguage.ru: 'Живой инцидент',
      AppLanguage.kk: 'Тікелей инцидент',
    },
    'detected_fire': {
      AppLanguage.en: 'Detected fire',
      AppLanguage.ru: 'Обнаружен пожар',
      AppLanguage.kk: 'Өрт анықталды',
    },
    'detected_car_accident': {
      AppLanguage.en: 'Detected car accident',
      AppLanguage.ru: 'Обнаружено ДТП',
      AppLanguage.kk: 'Жол апаты анықталды',
    },
    'manual_incident': {
      AppLanguage.en: 'Manual incident report',
      AppLanguage.ru: 'Ручной отчёт об инциденте',
      AppLanguage.kk: 'Қолмен енгізілген инцидент',
    },
    'analyze_before_saving': {
      AppLanguage.en:
          'Run detection and make sure an incident is found before saving.',
      AppLanguage.ru:
          'Перед сохранением выполните анализ и убедитесь, что инцидент найден.',
      AppLanguage.kk:
          'Сақтамас бұрын талдауды орындап, инцидент табылғанына көз жеткізіңіз.',
    },
    'overall_score': {
      AppLanguage.en: 'Overall score',
      AppLanguage.ru: 'Общий балл',
      AppLanguage.kk: 'Жалпы баға',
    },
    'city_score': {
      AppLanguage.en: 'City score',
      AppLanguage.ru: 'Оценка города',
      AppLanguage.kk: 'Қала бағасы',
    },
    'monitored_places': {
      AppLanguage.en: 'Monitored places',
      AppLanguage.ru: 'Отслеживаемые места',
      AppLanguage.kk: 'Бақыланатын орындар',
    },
    'open_issues': {
      AppLanguage.en: 'Open issues',
      AppLanguage.ru: 'Открытые проблемы',
      AppLanguage.kk: 'Ашық мәселелер',
    },
    'avg_fix_time': {
      AppLanguage.en: 'Avg time-to-fix',
      AppLanguage.ru: 'Среднее время исправления',
      AppLanguage.kk: 'Орташа түзету уақыты',
    },
    'city_operations': {
      AppLanguage.en: 'City operations',
      AppLanguage.ru: 'Городские операции',
      AppLanguage.kk: 'Қалалық операциялар',
    },
    'dashboard_title': {
      AppLanguage.en: 'Municipal signals in a structural glass control layer.',
      AppLanguage.ru:
          'Муниципальные сигналы в слое структурного стеклянного контроля.',
      AppLanguage.kk: 'Қалалық сигналдар structural glass бақылау қабатында.',
    },
    'dashboard_body': {
      AppLanguage.en:
          'A real-time overview of score health, maintenance pressure and high-priority places across the city.',
      AppLanguage.ru:
          'Обзор в реальном времени по качеству среды, нагрузке на обслуживание и приоритетным точкам города.',
      AppLanguage.kk:
          'Қала бойынша орта сапасы, қызмет көрсету қысымы және басым нүктелердің нақты уақыттағы көрінісі.',
    },
    'active_alerts': {
      AppLanguage.en: 'Active alerts',
      AppLanguage.ru: 'Активные сигналы',
      AppLanguage.kk: 'Белсенді дабылдар',
    },
    'top_places': {
      AppLanguage.en: 'Top places by urban syrix',
      AppLanguage.ru: 'Лучшие точки по urban syrix',
      AppLanguage.kk: 'urban syrix бойынша үздік орындар',
    },
    'profile': {
      AppLanguage.en: 'Profile',
      AppLanguage.ru: 'Профиль',
      AppLanguage.kk: 'Профиль',
    },
    'operator_profile': {
      AppLanguage.en: 'Authenticated operator profile.',
      AppLanguage.ru: 'Профиль авторизованного оператора.',
      AppLanguage.kk: 'Аутентификацияланған оператор профилі.',
    },
    'authenticated_supabase': {
      AppLanguage.en: 'Authenticated with Supabase',
      AppLanguage.ru: 'Аутентификация через Supabase',
      AppLanguage.kk: 'Supabase арқылы аутентификация',
    },
    'resident_workspace': {
      AppLanguage.en: 'Resident workspace',
      AppLanguage.ru: 'Режим жителя',
      AppLanguage.kk: 'Тұрғын режимі',
    },
    'builder_workspace': {
      AppLanguage.en: 'Builder workspace',
      AppLanguage.ru: 'Режим строителя',
      AppLanguage.kk: 'Құрылысшы режимі',
    },
    'admin_access': {
      AppLanguage.en: 'Administrator access enabled',
      AppLanguage.ru: 'Доступ администратора включён',
      AppLanguage.kk: 'Әкімші рұқсаты қосулы',
    },
    'resident_role': {
      AppLanguage.en: 'Resident',
      AppLanguage.ru: 'Житель',
      AppLanguage.kk: 'Тұрғын',
    },
    'builder_role': {
      AppLanguage.en: 'Builder',
      AppLanguage.ru: 'Строитель',
      AppLanguage.kk: 'Құрылысшы',
    },
    'admin_role': {
      AppLanguage.en: 'Administrator',
      AppLanguage.ru: 'Администратор',
      AppLanguage.kk: 'Әкімші',
    },
    'unknown_email': {
      AppLanguage.en: 'Unknown email',
      AppLanguage.ru: 'Неизвестный email',
      AppLanguage.kk: 'Белгісіз email',
    },
    'user_id': {
      AppLanguage.en: 'User id',
      AppLanguage.ru: 'User id',
      AppLanguage.kk: 'User id',
    },
    'role': {
      AppLanguage.en: 'Role',
      AppLanguage.ru: 'Роль',
      AppLanguage.kk: 'Рөл',
    },
    'unavailable': {
      AppLanguage.en: 'Unavailable',
      AppLanguage.ru: 'Недоступно',
      AppLanguage.kk: 'Қолжетімсіз',
    },
    'resident_workspace_body': {
      AppLanguage.en:
          'Use this role for reporting and monitoring local urban issues.',
      AppLanguage.ru:
          'Используйте эту роль для жалоб и мониторинга локальных городских проблем.',
      AppLanguage.kk:
          'Бұл рөлді жергілікті қалалық мәселелерді хабарлау және бақылау үшін пайдаланыңыз.',
    },
    'builder_workspace_body': {
      AppLanguage.en: 'Use this role for contractor and remediation workflows.',
      AppLanguage.ru:
          'Используйте эту роль для подрядчиков и сценариев устранения проблем.',
      AppLanguage.kk:
          'Бұл рөлді мердігерлер мен жөндеу процестері үшін пайдаланыңыз.',
    },
    'admin_access_body': {
      AppLanguage.en:
          'This account can be used for moderation and operational controls.',
      AppLanguage.ru:
          'Этот аккаунт можно использовать для модерации и операционного управления.',
      AppLanguage.kk:
          'Бұл аккаунтты модерация мен операциялық басқару үшін пайдалануға болады.',
    },
    'sign_out': {
      AppLanguage.en: 'Sign out',
      AppLanguage.ru: 'Выйти',
      AppLanguage.kk: 'Шығу',
    },
    'please_wait': {
      AppLanguage.en: 'Please wait...',
      AppLanguage.ru: 'Подождите...',
      AppLanguage.kk: 'Күте тұрыңыз...',
    },
    'score_breakdown': {
      AppLanguage.en: 'Score breakdown',
      AppLanguage.ru: 'Разбивка оценки',
      AppLanguage.kk: 'Баға бөлінісі',
    },
    'citizen_comments': {
      AppLanguage.en: 'Citizen comments',
      AppLanguage.ru: 'Комментарии жителей',
      AppLanguage.kk: 'Тұрғын пікірлері',
    },
    'leave_comment': {
      AppLanguage.en: 'Leave a comment',
      AppLanguage.ru: 'Оставить комментарий',
      AppLanguage.kk: 'Пікір қалдыру',
    },
    'enter_comment': {
      AppLanguage.en: 'Enter a comment.',
      AppLanguage.ru: 'Введите комментарий.',
      AppLanguage.kk: 'Пікір енгізіңіз.',
    },
    'comment_category': {
      AppLanguage.en: 'Comment category',
      AppLanguage.ru: 'Категория комментария',
      AppLanguage.kk: 'Пікір санаты',
    },
    'post_comment': {
      AppLanguage.en: 'Post comment',
      AppLanguage.ru: 'Отправить комментарий',
      AppLanguage.kk: 'Пікір жіберу',
    },
    'sign_in_to_comment': {
      AppLanguage.en: 'Sign in to leave a comment.',
      AppLanguage.ru: 'Войдите, чтобы оставить комментарий.',
      AppLanguage.kk: 'Пікір қалдыру үшін кіріңіз.',
    },
    'sign_in': {
      AppLanguage.en: 'Sign in',
      AppLanguage.ru: 'Войти',
      AppLanguage.kk: 'Кіру',
    },
    'comment_save_failed': {
      AppLanguage.en:
          'Saving the comment failed. Check Supabase reviews setup and try again.',
      AppLanguage.ru:
          'Не удалось сохранить комментарий. Проверьте настройку отзывов в Supabase.',
      AppLanguage.kk:
          'Пікірді сақтау сәтсіз. Supabase ішіндегі review баптауын тексеріңіз.',
    },
    'no_open_issues': {
      AppLanguage.en: 'No open issues.',
      AppLanguage.ru: 'Открытых проблем нет.',
      AppLanguage.kk: 'Ашық мәселе жоқ.',
    },
    'no_comments': {
      AppLanguage.en: 'No comments yet.',
      AppLanguage.ru: 'Комментариев пока нет.',
      AppLanguage.kk: 'Әзірге пікір жоқ.',
    },
    'days_open': {
      AppLanguage.en: 'days open',
      AppLanguage.ru: 'дней открыто',
      AppLanguage.kk: 'күн ашық',
    },
    'mobility': {
      AppLanguage.en: 'Mobility',
      AppLanguage.ru: 'Мобильность',
      AppLanguage.kk: 'Қозғалыс',
    },
    'environment': {
      AppLanguage.en: 'Environment',
      AppLanguage.ru: 'Экология',
      AppLanguage.kk: 'Экология',
    },
    'resources': {
      AppLanguage.en: 'Resources',
      AppLanguage.ru: 'Ресурсы',
      AppLanguage.kk: 'Ресурстар',
    },
    'transparency': {
      AppLanguage.en: 'Transparency',
      AppLanguage.ru: 'Прозрачность',
      AppLanguage.kk: 'Ашықтық',
    },
    'inclusivity': {
      AppLanguage.en: 'Inclusivity',
      AppLanguage.ru: 'Инклюзивность',
      AppLanguage.kk: 'Инклюзивтілік',
    },
    'safety': {
      AppLanguage.en: 'Safety',
      AppLanguage.ru: 'Безопасность',
      AppLanguage.kk: 'Қауіпсіздік',
    },
  };

  String tr(String key) => _strings[key]?[language] ?? key;

  String placeTypeLabel(UrbanPlaceType type) => switch (type) {
    UrbanPlaceType.building => tr('building'),
    UrbanPlaceType.construction => tr('construction'),
    UrbanPlaceType.road => tr('road'),
    UrbanPlaceType.incident => tr('incident'),
  };

  String incidentSubtypeLabel(IncidentSubtype subtype) => switch (subtype) {
    IncidentSubtype.fire => tr('incident_fire'),
    IncidentSubtype.carAccident => tr('incident_car_accident'),
    IncidentSubtype.other => tr('incident_other'),
  };

  String incidentDetectionLabel(IncidentSubtype subtype) => switch (subtype) {
    IncidentSubtype.fire => tr('detected_fire'),
    IncidentSubtype.carAccident => tr('detected_car_accident'),
    IncidentSubtype.other => tr('manual_incident'),
  };

  String categoryLabel(UrbanCategory category) => switch (category) {
    UrbanCategory.mobility => tr('mobility'),
    UrbanCategory.environment => tr('environment'),
    UrbanCategory.resources => tr('resources'),
    UrbanCategory.transparency => tr('transparency'),
    UrbanCategory.inclusivity => tr('inclusivity'),
    UrbanCategory.safety => tr('safety'),
  };

  String criterionLabel(ScoreCriterion criterion) => switch (criterion) {
    ScoreCriterion.overall => tr('overall_score'),
    ScoreCriterion.mobility => tr('mobility'),
    ScoreCriterion.environment => tr('environment'),
    ScoreCriterion.resources => tr('resources'),
    ScoreCriterion.transparency => tr('transparency'),
    ScoreCriterion.inclusivity => tr('inclusivity'),
    ScoreCriterion.safety => tr('safety'),
  };

  String roleLabel(String roleKey) => switch (roleKey) {
    'resident' => tr('resident_role'),
    'builder' => tr('builder_role'),
    'admin' => tr('admin_role'),
    _ => tr('resident_role'),
  };
}
