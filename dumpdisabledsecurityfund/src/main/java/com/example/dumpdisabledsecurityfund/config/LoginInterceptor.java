package com.example.dumpdisabledsecurityfund.config;

import com.example.dumpdisabledsecurityfund.util.JwtUtil;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class LoginInterceptor implements HandlerInterceptor {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    private static final List<String> EXCLUDE_PATHS = Arrays.asList(
            "/auth/login",
            "/auth/captcha",
            "/error",
            "/system/info"
    );

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        String uri = request.getRequestURI();

        // 处理双斜杠问题：将 // 替换为 /
        if (uri.startsWith("//")) {
            uri = uri.substring(1);
        }

        System.out.println("=== 拦截器检查请求: " + uri + " ===");

        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            System.out.println("=== OPTIONS请求，放行 ===");
            return true;
        }

        for (String excludePath : EXCLUDE_PATHS) {
            if (uri.equals(excludePath) || uri.startsWith(excludePath + "/")) {
                System.out.println("=== 白名单路径，放行: " + uri + " ===");
                return true;
            }
        }

        System.out.println("=== 需要验证Token: " + uri + " ===");
        String token = request.getHeader("Authorization");
        if (token == null || token.isEmpty()) {
            token = request.getParameter("token");
        }

        if (token == null || token.isEmpty()) {
            System.out.println("=== Token为空，拒绝访问 ===");
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

            System.out.println("=== Token验证通过 ===");
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
