package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
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

    @Operation(summary = "获取系统信息", description = "查询系统的基本配置和运行状态信息，无需登录即可访问")
    @GetMapping("/info")
    @RequirePermission(requireLogin = false)
    public Result<?> info() {
        return systemService.getSystemInfo();
    }
}
