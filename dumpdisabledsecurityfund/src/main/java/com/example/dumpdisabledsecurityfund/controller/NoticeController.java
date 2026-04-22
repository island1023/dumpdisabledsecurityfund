package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.service.NoticeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 通知控制器
 */
@Tag(name = "通知书管理", description = "缴费通知书的下载功能")
@RestController
@RequestMapping("/notice")
public class NoticeController {
    @Resource
    private NoticeService noticeService;

    @Operation(summary = "通知单管理列表", description = "市/区管理员查看通知单生成清单")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_city", "admin_district", "leader"})
    public Object list(
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer pageSize,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer noticeType,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Long regionId) {
        return noticeService.getAdminNoticeList(page, pageSize, year, noticeType, keyword, regionId);
    }

    @Operation(summary = "批量生成通知单", description = "按征收记录批量生成通知单")
    @PostMapping("/generate")
    @RequirePermission(roles = {"admin_city", "admin_district", "leader"})
    public Object generate(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<Object> ids = (List<Object>) request.get("payableIds");
        Integer noticeType = request.get("noticeType") == null ? 1 : Integer.valueOf(String.valueOf(request.get("noticeType")));
        List<Long> payableIds = ids == null ? List.of() : ids.stream().map(v -> Long.valueOf(String.valueOf(v))).toList();
        return noticeService.generateNotices(payableIds, noticeType);
    }

    @Operation(summary = "批量标记打印", description = "通知单打印后更新状态")
    @PostMapping("/print")
    @RequirePermission(roles = {"admin_city", "admin_district", "leader"})
    public Object print(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        List<Object> ids = (List<Object>) request.get("noticeIds");
        List<Long> noticeIds = ids == null ? List.of() : ids.stream().map(v -> Long.valueOf(String.valueOf(v))).toList();
        return noticeService.markPrinted(noticeIds);
    }

    @Operation(summary = "下载单个通知书", description = "生成并下载指定ID的缴费通知书PDF文件")
    @GetMapping("/download")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader", "company_user"})
    public void download(
            @Parameter(description = "通知书ID", required = true, example = "1")
            @RequestParam Long id,
            HttpServletResponse response) {
        noticeService.downloadNotice(id, response);
    }

    @Operation(summary = "预览单个通知书", description = "在线预览指定ID的缴费通知书PDF文件")
    @GetMapping("/preview")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader", "company_user"})
    public void preview(
            @Parameter(description = "通知书ID", required = true, example = "1")
            @RequestParam Long id,
            HttpServletResponse response) {
        noticeService.previewNotice(id, response);
    }

    @Operation(summary = "批量下载通知书", description = "将多个通知书打包成ZIP文件下载")
    @GetMapping("/downloadBatch")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader"})
    public void downloadBatch(
            @Parameter(description = "通知书ID列表", required = true)
            @RequestParam List<Long> ids,
            HttpServletResponse response) {
        noticeService.downloadNotices(ids, response);
    }
}
