package com.example.dumpdisabledsecurityfund.common;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class CaptchaStore {
    private static final long EXPIRE_MILLIS = 5 * 60 * 1000L;
    private final Map<String, CaptchaItem> data = new ConcurrentHashMap<>();

    public Map<String, String> create() {
        String key = UUID.randomUUID().toString().replace("-", "");
        String code = String.valueOf((int) ((Math.random() * 9 + 1) * 1000));
        data.put(key, new CaptchaItem(code, System.currentTimeMillis() + EXPIRE_MILLIS));
        return Map.of("captchaKey", key, "captchaCode", code, "expireInSeconds", "300");
    }

    public boolean validate(String key, String code) {
        if (key == null || code == null) {
            return false;
        }
        CaptchaItem item = data.remove(key);
        if (item == null) {
            return false;
        }
        if (System.currentTimeMillis() > item.expireAtMillis) {
            return false;
        }
        return item.code.equalsIgnoreCase(code.trim());
    }

    private static final class CaptchaItem {
        private final String code;
        private final long expireAtMillis;

        private CaptchaItem(String code, long expireAtMillis) {
            this.code = code;
            this.expireAtMillis = expireAtMillis;
        }
    }
}
