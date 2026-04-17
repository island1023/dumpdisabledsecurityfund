package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.service.NoticeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 通知控制器
 */
@Tag(name = "通知书管理", description = "缴费通知书的下载功能")
@RestController
@RequestMapping("/notice")
public class NoticeController {
    @Resource
    private NoticeService noticeService;

    @Operation(summary = "下载单个通知书", description = "生成并下载指定ID的缴费通知书PDF文件")
    @GetMapping("/download")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "company_user"})
    public void download(
            @Parameter(description = "通知书ID", required = true, example = "1")
            @RequestParam Long id,
            HttpServletResponse response) {
        noticeService.downloadNotice(id, response);
    }

    @Operation(summary = "批量下载通知书", description = "将多个通知书打包成ZIP文件下载")
    @GetMapping("/downloadBatch")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public void downloadBatch(
            @Parameter(description = "通知书ID列表", required = true)
            @RequestParam List<Long> ids,
            HttpServletResponse response) {
        noticeService.downloadNotices(ids, response);
    }
}
