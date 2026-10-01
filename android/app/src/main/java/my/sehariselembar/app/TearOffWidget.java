package my.sehariselembar.app;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.RemoteViews;
import java.util.Calendar;

/** "Tear-off" home screen widget: today's page, plus the peribahasa and next event when wide enough. */
public class TearOffWidget extends AppWidgetProvider {
    static final String ACTION_MIDNIGHT = "my.sehariselembar.app.WIDGET_MIDNIGHT";

    static void refreshAll(Context ctx) {
        AppWidgetManager mgr = AppWidgetManager.getInstance(ctx);
        int[] ids = mgr.getAppWidgetIds(new ComponentName(ctx, TearOffWidget.class));
        for (int id : ids) update(ctx, mgr, id);
        scheduleMidnight(ctx);
    }

    @Override
    public void onUpdate(Context ctx, AppWidgetManager mgr, int[] ids) {
        for (int id : ids) update(ctx, mgr, id);
        scheduleMidnight(ctx);
    }

    @Override
    public void onAppWidgetOptionsChanged(Context ctx, AppWidgetManager mgr, int id, Bundle options) {
        update(ctx, mgr, id);
    }

    @Override
    public void onReceive(Context ctx, Intent intent) {
        super.onReceive(ctx, intent);
        String a = intent.getAction();
        if (ACTION_MIDNIGHT.equals(a) || Intent.ACTION_TIME_CHANGED.equals(a) || Intent.ACTION_TIMEZONE_CHANGED.equals(a)) refreshAll(ctx);
    }

    @Override
    public void onDisabled(Context ctx) {
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am != null) am.cancel(midnightIntent(ctx));
    }

    static void update(Context ctx, AppWidgetManager mgr, int id) {
        Bundle opts = mgr.getAppWidgetOptions(id);
        int minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110);
        boolean wide = minW >= 220;
        WidgetData d = WidgetData.today(ctx);
        RemoteViews v = new RemoteViews(ctx.getPackageName(), wide ? R.layout.widget_tearoff_wide : R.layout.widget_tearoff_small);
        int red = 0xFFBF292A, ink = 0xFF28251E;
        v.setTextViewText(R.id.w_month, d.month + " " + d.year);
        v.setTextViewText(R.id.w_date, String.valueOf(d.dayOfMonth));
        v.setTextColor(R.id.w_date, d.red ? red : ink);
        v.setTextViewText(R.id.w_day, d.day);
        v.setTextColor(R.id.w_day, d.red ? red : ink);
        if (wide) {
            v.setTextViewText(R.id.w_langs, d.dayZh + "  ·  " + d.dayEn);
            boolean hasHoliday = !d.holiday.isEmpty();
            v.setViewVisibility(R.id.w_holiday, hasHoliday ? View.VISIBLE : View.GONE);
            v.setTextViewText(R.id.w_holiday, d.holiday);
            boolean hasPeri = !d.peribahasa.isEmpty();
            v.setViewVisibility(R.id.w_peri_block, hasPeri ? View.VISIBLE : View.GONE);
            v.setTextViewText(R.id.w_peri, "“" + d.peribahasa + "”");
            v.setTextViewText(R.id.w_maksud, d.maksud);
            boolean hasEvent = !d.eventTitle.isEmpty();
            v.setViewVisibility(R.id.w_event, hasEvent ? View.VISIBLE : View.GONE);
            v.setTextViewText(R.id.w_event, (d.eventTime.isEmpty() ? "Hari ini" : d.eventTime) + "   " + d.eventTitle);
        }
        Intent open = new Intent(ctx, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        v.setOnClickPendingIntent(R.id.w_root, PendingIntent.getActivity(ctx, 0, open, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE));
        mgr.updateAppWidget(id, v);
    }

    private static PendingIntent midnightIntent(Context ctx) {
        Intent i = new Intent(ctx, TearOffWidget.class).setAction(ACTION_MIDNIGHT);
        return PendingIntent.getBroadcast(ctx, 1, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    /** Turn the page just after midnight (inexact alarms need no special permission). */
    static void scheduleMidnight(Context ctx) {
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am == null) return;
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DAY_OF_MONTH, 1);
        c.set(Calendar.HOUR_OF_DAY, 0);
        c.set(Calendar.MINUTE, 0);
        c.set(Calendar.SECOND, 30);
        am.setAndAllowWhileIdle(AlarmManager.RTC, c.getTimeInMillis(), midnightIntent(ctx));
    }
}
