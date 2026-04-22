package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.UploadService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
public class UploadServiceImpl implements UploadService {

    private static final String UPLOAD_DIR = "uploads/";

    // 允许的图片格式
    private static final String[] ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"};
    // 允许的文档格式
    private static final String[] ALLOWED_DOC_EXTENSIONS = {".pdf", ".doc", ".docx", ".txt", ".rtf"};
    // 允许的Excel格式
    private static final String[] ALLOWED_EXCEL_EXTENSIONS = {".xls", ".xlsx", ".csv"};

    // 文件大小限制（50MB）
    private static final long MAX_FILE_SIZE = 50 * 1024 * 1024;

    @Override
    public Result<Map<String, Object>> uploadFile(MultipartFile file, String type) {
        log.info(">>> 开始上传文件: {}, 类型: {}", file.getOriginalFilename(), type);

        // 1. 基础验证
        if (file == null || file.isEmpty()) {
            log.error(">>> 文件上传失败: 文件为空");
            return Result.error("文件不能为空");
        }

        if (type == null || type.isEmpty()) {
            log.error(">>> 文件上传失败: 类型为空");
            return Result.error("文件类型不能为空");
        }

        // 2. 验证文件类型
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.isEmpty()) {
            log.error(">>> 文件上传失败: 文件名无效");
            return Result.error("文件名无效");
        }

        String extension = getFileExtension(originalFilename).toLowerCase();
        if (!isValidFileType(type, extension)) {
            log.error(">>> 文件上传失败: 不支持的文件类型 {}, 期望类型: {}", extension, type);
            return Result.error("不支持的文件类型，请上传符合要求的文件");
        }

        // 3. 验证文件大小
        if (file.getSize() > MAX_FILE_SIZE) {
            log.error(">>> 文件上传失败: 文件大小超限 {} bytes", file.getSize());
            return Result.error("文件大小不能超过50MB");
        }

        try {
            // 4. 生成唯一文件名
            String fileName = UUID.randomUUID().toString() + extension;

            // 5. 创建上传目录
            Path uploadPath = Paths.get(UPLOAD_DIR + type);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
                log.info(">>> 创建上传目录: {}", uploadPath.toAbsolutePath());
            }

            // 6. 保存文件
            Path filePath = uploadPath.resolve(fileName);
            Files.copy(file.getInputStream(), filePath);

            String fileUrl = "/uploads/" + type + "/" + fileName;

            // 7. 构建返回结果
            Map<String, Object> result = new HashMap<>();
            result.put("url", fileUrl);
            result.put("fileName", originalFilename);
            result.put("fileSize", file.getSize());
            result.put("fileType", getFileTypeDescription(extension));

            log.info(">>> 文件上传成功: URL={}, 大小={} bytes, 类型={}",
                    fileUrl, file.getSize(), extension);
            return Result.success("上传成功", result);

        } catch (IOException e) {
            log.error(">>> 文件上传异常: ", e);
            return Result.error("上传失败：" + e.getMessage());
        }
    }

    /**
     * 获取文件扩展名
     */
    private String getFileExtension(String filename) {
        int lastDotIndex = filename.lastIndexOf(".");
        if (lastDotIndex > 0 && lastDotIndex < filename.length() - 1) {
            return filename.substring(lastDotIndex);
        }
        return "";
    }

    /**
     * 验证文件类型是否合法
     */
    /**
     * 验证文件类型是否合法
     */
    private boolean isValidFileType(String type, String extension) {
        switch (type.toLowerCase()) {
            case "certificate":
                // 证书只支持图片格式
                return isImageExtension(extension);
            case "attachment":
                // 减免缓附件支持图片、文档和Excel格式
                return isImageExtension(extension) || isDocumentExtension(extension) || isExcelExtension(extension);
            case "excel":
            case "import":
                // Excel导入只支持Excel格式
                return isExcelExtension(extension);
            default:
                log.warn(">>> 未知文件类型: {}, 默认允许所有格式", type);
                return true;
        }
    }

    /**
     * 判断是否为图片格式
     */
    private boolean isImageExtension(String extension) {
        for (String allowedExt : ALLOWED_IMAGE_EXTENSIONS) {
            if (allowedExt.equals(extension)) {
                return true;
            }
        }
        return false;
    }

    /**
     * 判断是否为文档格式
     */
    private boolean isDocumentExtension(String extension) {
        for (String allowedExt : ALLOWED_DOC_EXTENSIONS) {
            if (allowedExt.equals(extension)) {
                return true;
            }
        }
        return false;
    }

    /**
     * 判断是否为Excel格式
     */
    private boolean isExcelExtension(String extension) {
        for (String allowedExt : ALLOWED_EXCEL_EXTENSIONS) {
            if (allowedExt.equals(extension)) {
                return true;
            }
        }
        return false;
    }

    /**
     * 获取文件类型描述
     */
    private String getFileTypeDescription(String extension) {
        if (isImageExtension(extension)) {
            return "图片";
        } else if (isDocumentExtension(extension)) {
            return "文档";
        } else if (isExcelExtension(extension)) {
            return "Excel";
        }
        return "其他";
    }
}
