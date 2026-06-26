package com.locketclone.locket_clone

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class LocketWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("widget_title", "Tap to open Glimpse")
                setTextViewText(R.id.widget_title, title)

                val imagePath = widgetData.getString("widget_image", null)
                if (imagePath != null) {
                    val imageFile = File(imagePath)
                    if (imageFile.exists()) {
                        val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                        setImageViewBitmap(R.id.widget_image, bitmap)
                    }
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
