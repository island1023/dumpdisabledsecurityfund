package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.RegionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 区域控制器
 */
@Tag(name = "区域管理", description = "行政区域数据的查询功能")
@RestController
@RequestMapping("/region")
public class RegionController {
    @Resource
    private RegionService regionService;

    @Operation(summary = "查询区域列表", description = "获取所有行政区域信息，包括省市区三级联动数据")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> list() {
        return regionService.list();
    }
}

