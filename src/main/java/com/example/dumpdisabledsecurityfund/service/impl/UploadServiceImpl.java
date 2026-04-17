package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.UploadService;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class UploadServiceImpl implements UploadService {

    private static final String UPLOAD_DIR = "uploads/";

    @Override
    public Result<?> uploadFile(MultipartFile file, String type) {
        if (file == null || file.isEmpty()) {
            return Result.error("文件不能为空");
        }

        if (type == null || type.isEmpty()) {
            return Result.error("文件类型不能为空");
        }

        try {
            String originalFilename = file.getOriginalFilename();
            if (originalFilename == null || originalFilename.isEmpty()) {
                return Result.error("文件名无效");
            }

            String extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            String fileName = UUID.randomUUID().toString() + extension;

            Path uploadPath = Paths.get(UPLOAD_DIR + type);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            Path filePath = uploadPath.resolve(fileName);
            Files.copy(file.getInputStream(), filePath);

            String fileUrl = "/uploads/" + type + "/" + fileName;

            Map<String, Object> result = new HashMap<>();
            result.put("url", fileUrl);
            result.put("fileName", originalFilename);
            result.put("fileSize", file.getSize());

            return Result.success("上传成功", result);

        } catch (IOException e) {
            return Result.error("上传失败：" + e.getMessage());
        }
    }
}

