package com.example.dumpdisabledsecurityfund.config;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Aspect
@Component
public class PermissionAspect {

    @Around("@annotation(com.example.dumpdisabledsecurityfund.common.RequirePermission)")
    public Object checkPermission(ProceedingJoinPoint joinPoint) throws Throwable {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return Result.error("无法获取请求上下文");
        }

        HttpServletRequest request = attributes.getRequest();
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
        RequirePermission permission = method.getAnnotation(RequirePermission.class);

        if (permission == null) {
            permission = joinPoint.getTarget().getClass().getAnnotation(RequirePermission.class);
        }

        if (permission != null && permission.requireLogin()) {
            Object userInfo = request.getAttribute("userInfo");
            if (userInfo == null) {
                return Result.unauthorized("请先登录");
            }

            Map<String, Object> claims = (Map<String, Object>) userInfo;
            String accountType = (String) claims.get("accountType");

            if (permission.roles().length > 0) {
                List<String> requiredRoles = Arrays.asList(permission.roles());

                if ("sys".equals(accountType)) {
                    List<String> userRoles = (List<String>) claims.get("roleCodes");
                    if (userRoles == null || userRoles.stream().noneMatch(requiredRoles::contains)) {
                        return Result.forbidden("权限不足，需要角色: " + String.join(",", permission.roles()));
                    }
                } else if ("company".equals(accountType)) {
                    if (!requiredRoles.contains("company_user")) {
                        return Result.forbidden("权限不足");
                    }
                }
            }
        }

        return joinPoint.proceed();
    }
}
