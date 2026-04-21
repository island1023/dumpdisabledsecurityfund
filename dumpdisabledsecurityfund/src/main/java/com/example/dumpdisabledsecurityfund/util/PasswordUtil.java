package com.example.dumpdisabledsecurityfund.util;

import org.springframework.util.DigestUtils;
import java.util.Random;

public class PasswordUtil {

    public static String randomPwd(int length) {
        String str = "ABCDEFGHJKLMNPQRSTWXY23456789";
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++) {
            sb.append(str.charAt(random.nextInt(str.length())));
        }
        return sb.toString();
    }

    public static String encrypt(String password) {
        return DigestUtils.md5DigestAsHex(password.getBytes());
    }
}