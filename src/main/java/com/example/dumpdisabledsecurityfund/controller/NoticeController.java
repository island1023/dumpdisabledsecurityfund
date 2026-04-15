package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.service.NoticeService;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/notice")
public class NoticeController {
    @Resource
    private NoticeService noticeService;

    @GetMapping("/download")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "company_user"})
    public void download(@RequestParam Long id, HttpServletResponse response) {
        noticeService.downloadNotice(id, response);
    }

    @GetMapping("/downloadBatch")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public void downloadBatch(@RequestParam List<Long> ids, HttpServletResponse response) {
        noticeService.downloadNotices(ids, response);
    }
}
