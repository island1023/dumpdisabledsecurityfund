package com.example.dumpdisabledsecurityfund.util;

import com.example.dumpdisabledsecurityfund.common.Constants;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

public class DateUtil {
    public static String now() {
        return new SimpleDateFormat(Constants.DATE_FORMAT).format(new Date());
    }

    public static Integer getCurrentYear() {
        return Calendar.getInstance().get(Calendar.YEAR);
    }

    public static String today() {
        return new SimpleDateFormat(Constants.DATE_FORMAT).format(new Date());
    }
}