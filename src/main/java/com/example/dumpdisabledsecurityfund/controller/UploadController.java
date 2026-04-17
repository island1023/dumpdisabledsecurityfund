package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.UploadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "文件上传", description = "通用文件上传功能")
@RestController
@RequestMapping("/upload")
public class UploadController {
    @Resource
    private UploadService uploadService;

    @Operation(summary = "通用文件上传", description = "上传证书、附件、Excel等文件")
    @PostMapping("/file")
    @RequirePermission(requireLogin = true)
    public Result<?> uploadFile(
            @Parameter(description = "文件对象", required = true)
            @RequestParam("file") MultipartFile file,
            @Parameter(description = "文件类型：certificate-证书/attachment-附件/excel-Excel文件", required = true, example = "attachment")
            @RequestParam("type") String type) {
        return uploadService.uploadFile(file, type);
    }
}
