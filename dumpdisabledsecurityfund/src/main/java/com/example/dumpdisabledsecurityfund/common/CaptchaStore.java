package com.example.dumpdisabledsecurityfund.common;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class CaptchaStore {

    private static final long EXPIRE_SECONDS = 300;

    private static final String CAPTCHA_KEY_PREFIX = "captcha:";

    // 使用内存存储替代Redis
    private final Map<String, CaptchaInfo> captchaStore = new ConcurrentHashMap<>();

    @Value("${dev.captcha.show-code:false}")
    private boolean showCode;

    public Map<String, String> create() {
        String key = UUID.randomUUID().toString().replace("-", "");

        String code = String.valueOf((int) ((Math.random() * 9 + 1) * 1000));

        String base64Image = generateCaptchaImage(code);

        // 存储到内存
        captchaStore.put(CAPTCHA_KEY_PREFIX + key, new CaptchaInfo(code, System.currentTimeMillis() + EXPIRE_SECONDS * 1000));

        Map<String, String> result = new HashMap<>();
        result.put("captchaKey", key);
        result.put("captchaImage", base64Image);
        result.put("expireInSeconds", String.valueOf(EXPIRE_SECONDS));

        if (showCode) {
            result.put("captchaCode", code);
        }

        // 清理过期验证码
        cleanupExpiredCaptchas();

        return result;
    }

    public boolean validate(String key, String code) {
        if (key == null || code == null) {
            return false;
        }

        // 清理过期验证码
        cleanupExpiredCaptchas();

        // 从内存获取
        CaptchaInfo captchaInfo = captchaStore.remove(CAPTCHA_KEY_PREFIX + key);

        if (captchaInfo == null) {
            return false;
        }

        // 检查是否过期
        if (System.currentTimeMillis() > captchaInfo.getExpireTime()) {
            return false;
        }

        return captchaInfo.getCode().equalsIgnoreCase(code.trim());
    }

    // 清理过期验证码
    private void cleanupExpiredCaptchas() {
        long currentTime = System.currentTimeMillis();
        captchaStore.entrySet().removeIf(entry -> entry.getValue().getExpireTime() < currentTime);
    }

    // 验证码信息类
    private static class CaptchaInfo {
        private final String code;
        private final long expireTime;

        public CaptchaInfo(String code, long expireTime) {
            this.code = code;
            this.expireTime = expireTime;
        }

        public String getCode() {
            return code;
        }

        public long getExpireTime() {
            return expireTime;
        }
    }

    private String generateCaptchaImage(String code) {
        int width = 120;
        int height = 40;

        BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        Graphics2D g2d = image.createGraphics();

        g2d.setColor(Color.WHITE);
        g2d.fillRect(0, 0, width, height);

        g2d.setFont(new Font("Arial", Font.BOLD, 28));

        for (int i = 0; i < 5; i++) {
            g2d.setColor(randomColor(150, 200));
            int x1 = (int) (Math.random() * width);
            int y1 = (int) (Math.random() * height);
            int x2 = (int) (Math.random() * width);
            int y2 = (int) (Math.random() * height);
            g2d.drawLine(x1, y1, x2, y2);
        }

        for (int i = 0; i < code.length(); i++) {
            g2d.setColor(randomColor(50, 100));
            Graphics2D g2dCopy = (Graphics2D) g2d.create();
            double angle = (Math.random() - 0.5) * 0.4;
            g2dCopy.rotate(angle, 20 + i * 25, height / 2);
            g2dCopy.drawString(String.valueOf(code.charAt(i)), 20 + i * 25, height - 10);
            g2dCopy.dispose();
        }

        for (int i = 0; i < 50; i++) {
            g2d.setColor(randomColor(150, 200));
            int x = (int) (Math.random() * width);
            int y = (int) (Math.random() * height);
            g2d.fillOval(x, y, 2, 2);
        }

        g2d.dispose();

        try {
            java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
            javax.imageio.ImageIO.write(image, "png", baos);
            byte[] bytes = baos.toByteArray();
            String base64 = Base64.getEncoder().encodeToString(bytes);
            return "data:image/png;base64," + base64;
        } catch (Exception e) {
            throw new RuntimeException("生成验证码图片失败", e);
        }
    }

    private Color randomColor(int min, int max) {
        int r = min + (int) (Math.random() * (max - min));
        int g = min + (int) (Math.random() * (max - min));
        int b = min + (int) (Math.random() * (max - min));
        return new Color(r, g, b);
    }
}