package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.UploadService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@Tag(name = "文件上传", description = "通用文件上传功能")
@RestController
@RequestMapping("/upload")
public class UploadController {
    @Resource
    private UploadService uploadService;

    @Operation(
            summary = "通用文件上传",
            description = "上传证书、附件、Excel等文件\n" +
                    "- certificate: 残疾证（支持图片格式：jpg, jpeg, png, gif, bmp, webp）\n" +
                    "- attachment: 减免缓申请附件（支持图片和文档：jpg, jpeg, png, pdf, doc, docx）\n" +
                    "- excel: Excel导入文件（支持：xls, xlsx, csv）"
    )
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "上传成功"),
            @ApiResponse(responseCode = "400", description = "文件类型不支持或文件大小超限"),
            @ApiResponse(responseCode = "500", description = "服务器内部错误")
    })
    @PostMapping("/file")
    @RequirePermission(requireLogin = true)
    public Result<?> uploadFile(
            @Parameter(description = "文件对象", required = true)
            @RequestParam("file") MultipartFile file,
            @Parameter(
                    description = "文件类型：certificate-证书/attachment-附件/excel-Excel文件",
                    required = true,
                    example = "attachment"
            )
            @RequestParam("type") String type) {
        return uploadService.uploadFile(file, type);
    }
}