package com.example.mystic_ledger

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget showing the current ledger balance.
 *
 * The widget is a dumb renderer: all values are pushed from Dart via
 * `HomeWidget.saveWidgetData` and read here from [widgetData]. Tapping the
 * card opens the app; tapping the "Add Entry" button opens it on the
 * `mysticledger://addEntry` deep link, which the app resolves by pushing the
 * entry form.
 */
class BalanceWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.balance_widget).apply {
                // Whole card opens the app.
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                // "Add Entry" button opens straight to the entry form.
                setOnClickPendingIntent(
                    R.id.widget_add_entry,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("mysticledger://addEntry"),
                    ),
                )

                setTextViewText(
                    R.id.widget_balance,
                    widgetData.getString("balance", null) ?: "—",
                )
                setTextViewText(
                    R.id.widget_label,
                    widgetData.getString("label", null) ?: "BALANCE",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
