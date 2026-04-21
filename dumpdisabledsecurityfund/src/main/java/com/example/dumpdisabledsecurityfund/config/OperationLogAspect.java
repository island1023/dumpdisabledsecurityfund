package com.example.dumpdisabledsecurityfund.config;

import com.example.dumpdisabledsecurityfund.service.OperationLogService;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

@Aspect
@Component
public class OperationLogAspect {

    private static final Logger log = LoggerFactory.getLogger(OperationLogAspect.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Resource
    private OperationLogService operationLogService;

    @AfterReturning(pointcut = "@annotation(com.example.dumpdisabledsecurityfund.common.LogOperation)", returning = "result")
    public void afterReturning(JoinPoint joinPoint, Object result) {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes == null) {
                return;
            }

            HttpServletRequest request = attributes.getRequest();

            Long userId = getUserIdFromRequest(request);
            if (userId == null) {
                return;
            }

            MethodSignature signature = (MethodSignature) joinPoint.getSignature();
            Method method = signature.getMethod();
            com.example.dumpdisabledsecurityfund.common.LogOperation logAnnotation =
                    method.getAnnotation(com.example.dumpdisabledsecurityfund.common.LogOperation.class);

            if (logAnnotation == null) {
                return;
            }

            String operationType = logAnnotation.value();
            String targetTable = logAnnotation.table();

            Long targetId = extractTargetId(joinPoint.getArgs());

            String detail = buildDetail(joinPoint.getArgs(), result);

            String ipAddress = getClientIp(request);

            operationLogService.logOperation(userId, operationType, targetTable, targetId, detail, ipAddress);

        } catch (Exception e) {
            log.error("记录操作日志失败", e);
        }
    }

    private Long getUserIdFromRequest(HttpServletRequest request) {
        Object userId = request.getAttribute("userId");
        if (userId != null) {
            try {
                return Long.valueOf(userId.toString());
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    private Long extractTargetId(Object[] args) {
        for (Object arg : args) {
            if (arg instanceof Long) {
                return (Long) arg;
            }
            if (arg instanceof Number) {
                return ((Number) arg).longValue();
            }
        }
        return null;
    }

    private String buildDetail(Object[] args, Object result) {
        try {
            Map<String, Object> detailMap = new HashMap<>();
            detailMap.put("argsCount", args.length);
            detailMap.put("success", result != null && result.toString().contains("success"));
            return objectMapper.writeValueAsString(detailMap);
        } catch (Exception e) {
            return "操作完成";
        }
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("X-Real-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        return ip;
    }
}
