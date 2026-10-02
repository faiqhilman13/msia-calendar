package my.sehariselembar.app;

import android.content.Context;
import android.content.SharedPreferences;
import java.util.Calendar;
import java.util.Locale;
import org.json.JSONArray;
import org.json.JSONObject;

/** Today's sheet for the widget: from the app's snapshot when there is one, otherwise just the date. */
final class WidgetData {
    private static final String PREFS = "sehari_widget";
    private static final String KEY = "snapshot";
    private static final String[] DAYS = {"AHAD", "ISNIN", "SELASA", "RABU", "KHAMIS", "JUMAAT", "SABTU"};
    private static final String[] DAYS_EN = {"SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"};
    private static final String[] DAYS_ZH = {"星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"};
    private static final String[] MONTHS_EN = {"JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"};
    private static final String[] MONTHS_ZH = {"一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"};

    // English leads; `day` is the Malay day name for the language line. holiday and maksud prefer English.
    String date, monthEn, monthZh, day, dayEn, dayZh, holiday, peribahasa, maksud, eventTime, eventTitle;
    int dayOfMonth, year;
    boolean red;

    private WidgetData() {}

    static void save(Context ctx, String json) {
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply();
    }

    static WidgetData today(Context ctx) {
        Calendar c = Calendar.getInstance();
        WidgetData w = new WidgetData();
        w.year = c.get(Calendar.YEAR);
        w.dayOfMonth = c.get(Calendar.DAY_OF_MONTH);
        int dow = c.get(Calendar.DAY_OF_WEEK) - 1, m = c.get(Calendar.MONTH);
        w.date = String.format(Locale.ROOT, "%04d-%02d-%02d", w.year, m + 1, w.dayOfMonth);
        w.monthEn = MONTHS_EN[m];
        w.monthZh = MONTHS_ZH[m];
        w.day = DAYS[dow];
        w.dayEn = DAYS_EN[dow];
        w.dayZh = DAYS_ZH[dow];
        w.red = dow == 0;
        w.holiday = w.peribahasa = w.maksud = w.eventTime = w.eventTitle = "";
        SharedPreferences prefs = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        try {
            JSONObject snap = new JSONObject(prefs.getString(KEY, "{}"));
            JSONArray days = snap.optJSONArray("days");
            for (int i = 0; days != null && i < days.length(); i++) {
                JSONObject d = days.getJSONObject(i);
                if (!w.date.equals(d.optString("date"))) continue;
                w.red = d.optBoolean("red", w.red);
                w.holiday = firstNonEmpty(d.optString("holidayEn", ""), d.optString("holiday", ""));
                w.peribahasa = d.optString("peribahasa", "");
                w.maksud = firstNonEmpty(d.optString("maksudEn", ""), d.optString("maksud", ""));
                w.dayZh = d.optString("dayZh", w.dayZh);
                w.monthZh = d.optString("monthZh", w.monthZh);
                JSONArray ev = d.optJSONArray("events");
                if (ev != null && ev.length() > 0) {
                    JSONObject e = ev.getJSONObject(0);
                    w.eventTime = e.optString("time", "");
                    w.eventTitle = e.optString("title", "");
                }
                return w;
            }
            // The days run out 21 days after the app was last opened. The holidays, listed for a year, still show.
            JSONObject holidays = snap.optJSONObject("holidays");
            JSONObject h = holidays == null ? null : holidays.optJSONObject(w.date);
            if (h != null) {
                w.red = true;
                w.holiday = firstNonEmpty(h.optString("en", ""), h.optString("ms", ""));
            }
        } catch (Exception ignored) {
            // A damaged snapshot still leaves a correct date on the widget.
        }
        return w;
    }

    private static String firstNonEmpty(String a, String b) {
        return a.isEmpty() ? b : a;
    }
}
