import 'package:flutter/material.dart';

/// GlobalKey để ApiService có thể redirect về login khi token hết hạn
/// mà không cần BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
