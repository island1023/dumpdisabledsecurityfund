package com.example.dumpdisabledsecurityfund.util;

public class SnowflakeIdUtil {
    private static long id = 0;

    public static long nextId() {
        return ++id;
    }
}