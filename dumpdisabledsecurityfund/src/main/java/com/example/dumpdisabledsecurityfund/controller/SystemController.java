package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.NoticeMapper;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.service.SystemService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 系统控制器
 */
@Tag(name = "系统信息", description = "系统基本信息查询功能")
@RestController
@RequestMapping("/system")
public class SystemController {
    @Resource
    private SystemService systemService;
    @Resource
    private CompanyMapper companyMapper;
    @Resource
    private NoticeMapper noticeMapper;
    @Resource
    private PayableAmountMapper payableAmountMapper;

    @Operation(summary = "获取系统信息", description = "查询系统的基本配置和运行状态信息，无需登录即可访问")
    @GetMapping("/info")
    @RequirePermission(requireLogin = false)
    public Result<?> info() {
        return systemService.getSystemInfo();
    }

    @Operation(summary = "数据库连通检查", description = "返回关键业务表记录数，用于确认是否真正连接数据库")
    @GetMapping("/db-check")
    @RequirePermission(requireLogin = false)
    public Result<?> dbCheck() {
        java.util.Map<String, Object> data = new java.util.HashMap<>();
        data.put("companyCount", companyMapper.countAll());
        data.put("noticeCount", noticeMapper.countAll());
        data.put("payableAmountCount", payableAmountMapper.selectAll().size());
        data.put("timestamp", System.currentTimeMillis());
        return Result.success(data);
    }
}
