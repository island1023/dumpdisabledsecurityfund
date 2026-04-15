package com.example.dumpdisabledsecurityfund.util;

import org.springframework.util.StringUtils;

public class ValidationUtil {

    // 闈炵┖鏍￠獙
    public static boolean isEmpty(String str) {
        return !StringUtils.hasText(str);
    }

    // 鎵嬫満鍙锋牎楠?
    public static boolean isPhone(String phone) {
        if (isEmpty(phone)) return false;
        return phone.matches("^1[3-9]\\d{9}$");
    }

    // 韬唤璇佹牎楠?
    public static boolean isIdCard(String idCard) {
        if (isEmpty(idCard)) return false;
        return idCard.matches("^\\d{17}[0-9Xx]$");
    }

    // 缁熶竴绀句細淇＄敤浠ｇ爜鏍￠獙
    public static boolean isCreditCode(String code) {
        if (isEmpty(code)) return false;
        return code.length() == 18;
    }
}