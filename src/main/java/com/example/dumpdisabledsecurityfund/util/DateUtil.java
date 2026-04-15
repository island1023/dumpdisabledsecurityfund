package com.example.dumpdisabledsecurityfund.util;

import com.example.dumpdisabledsecurityfund.common.Constants;
import java.text.SimpleDateFormat;
import java.util.Date;

public class DateUtil {
    public static String now() {
        return new SimpleDateFormat(Constants.DATE_FORMAT).format(new Date());
    }
}