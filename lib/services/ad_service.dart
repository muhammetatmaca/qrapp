// Conditional export for AdService
// Uses web stub on web, mobile implementation on Android/iOS

export 'ad_service_web.dart'
    if (dart.library.io) 'ad_service_mobile.dart';
