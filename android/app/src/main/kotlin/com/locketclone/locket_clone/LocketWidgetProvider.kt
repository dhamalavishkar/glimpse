package com.locketclone.locket_clone

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
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

                val streak = widgetData.getInt("widget_streak", 0)
                if (streak >= 50) {
                    setInt(R.id.widget_root, "setBackgroundColor", android.graphics.Color.parseColor("#FFD700"))
                    setViewPadding(R.id.widget_root, 12, 12, 12, 12)
                } else {
                    setInt(R.id.widget_root, "setBackgroundColor", android.graphics.Color.BLACK)
                    setViewPadding(R.id.widget_root, 0, 0, 0, 0)
                }

                val imagePath = widgetData.getString("widget_image", null)
                if (imagePath != null) {
                    val imageFile = File(imagePath)
                    if (imageFile.exists()) {
                        val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                        setImageViewBitmap(R.id.widget_image, bitmap)
                        setViewVisibility(R.id.widget_title, View.GONE)
                    } else {
                        setViewVisibility(R.id.widget_title, View.VISIBLE)
                    }
                } else {
                    setViewVisibility(R.id.widget_title, View.VISIBLE)
                }

                val note = widgetData.getString("widget_note", null)
                if (!note.isNullOrEmpty()) {
                    setTextViewText(R.id.widget_note, note)
                    setViewVisibility(R.id.widget_note, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.widget_note, View.GONE)
                }

                // Add tap-to-open functionality
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (intent != null) {
                    val pendingIntent = PendingIntent.getActivity(
                        context, 
                        appWidgetId, 
                        intent, 
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
