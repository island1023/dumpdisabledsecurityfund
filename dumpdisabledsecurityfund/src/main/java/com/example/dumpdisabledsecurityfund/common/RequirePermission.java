package com.example.dumpdisabledsecurityfund.common;

import java.lang.annotation.*;

@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RequirePermission {
    String[] value() default {};
    String[] roles() default {};
    boolean requireLogin() default true;
}
