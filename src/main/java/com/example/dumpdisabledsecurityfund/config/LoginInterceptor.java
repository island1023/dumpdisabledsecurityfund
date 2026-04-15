package com.example.dumpdisabledsecurityfund.config;

import com.example.dumpdisabledsecurityfund.util.JwtUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.HashMap;
import java.util.Map;

@Component
public class LoginInterceptor implements HandlerInterceptor {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String token = request.getHeader("Authorization");

        if (token == null || token.isEmpty()) {
            sendErrorResponse(response, 401, "未登录或Token已过期");
            return false;
        }

        if (token.startsWith("Bearer ")) {
            token = token.substring(7);
        }

        try {
            Map<String, Object> claims = JwtUtil.parseToken(token);
            if (claims == null || claims.isEmpty()) {
                sendErrorResponse(response, 401, "Token无效或已过期");
                return false;
            }

            request.setAttribute("userInfo", claims);
            request.setAttribute("userId", claims.get("userId"));
            request.setAttribute("accountType", claims.get("accountType"));

            if (claims.containsKey("companyId")) {
                request.setAttribute("companyId", claims.get("companyId"));
            }

            return true;
        } catch (Exception e) {
            sendErrorResponse(response, 401, "Token解析失败: " + e.getMessage());
            return false;
        }
    }

    private void sendErrorResponse(HttpServletResponse response, int status, String message) throws Exception {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");

        Map<String, Object> result = new HashMap<>();
        result.put("code", status);
        result.put("message", message);
        result.put("success", false);
        result.put("timestamp", System.currentTimeMillis());

        response.getWriter().write(objectMapper.writeValueAsString(result));
    }
}
