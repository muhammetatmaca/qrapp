// Conditional export for native ad widget
// Uses web stub on web, mobile implementation on Android/iOS

export 'native_ad_widget_web.dart'
    if (dart.library.io) 'native_ad_widget_mobile.dart';
