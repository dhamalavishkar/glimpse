import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String androidWidgetName = 'LocketWidgetProvider';
  
  static Future<void> init() async {
    await HomeWidget.setAppGroupId('group.com.locketclone.locket_clone');
  }

  static Future<void> updateWidget({required String imagePath, required String senderName, int streak = 0, String? note}) async {
    // Save data to SharedPreferences for the widget to read
    await HomeWidget.saveWidgetData<String>('widget_image', imagePath);
    await HomeWidget.saveWidgetData<String>('widget_title', 'From $senderName');
    await HomeWidget.saveWidgetData<int>('widget_streak', streak);
    if (note != null) {
      await HomeWidget.saveWidgetData<String>('widget_note', note);
    } else {
      await HomeWidget.saveWidgetData<String>('widget_note', '');
    }
    
    // Trigger the widget update
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      androidName: androidWidgetName,
    );
  }
}
