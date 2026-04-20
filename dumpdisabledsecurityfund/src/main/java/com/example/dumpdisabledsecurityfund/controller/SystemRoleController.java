package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Role;
import com.example.dumpdisabledsecurityfund.service.RoleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

@Tag(name = "角色管理(PDF规范)", description = "符合PDF文档规范的角色管理接口")
@RestController
@RequestMapping("/system/roles")
public class SystemRoleController {
    @Resource
    private RoleService roleService;

    @Operation(summary = "获取角色列表", description = "获取系统角色列表，支持关键词搜索")
    @GetMapping
    @RequirePermission(roles = {"admin_system"})
    public Result<?> list(
            @Parameter(description = "搜索关键词（匹配name或code）", example = "管理员")
            @RequestParam(required = false) String keyword) {
        return roleService.listWithKeyword(keyword);
    }

    @Operation(summary = "编辑角色", description = "修改角色名称、编码、描述和权限配置")
    @PutMapping("/{roleId}")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> update(
            @Parameter(description = "角色ID", required = true, example = "1")
            @PathVariable Long roleId,
            @Parameter(description = "角色信息", required = true)
            @RequestBody Role role) {
        role.setId(roleId);
        return roleService.update(role);
    }

    @Operation(summary = "切换角色状态", description = "启用或禁用角色")
    @PutMapping("/{roleId}/status")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> toggleStatus(
            @Parameter(description = "角色ID", required = true, example = "1")
            @PathVariable Long roleId,
            @Parameter(description = "状态：启用或禁用", required = true, example = "启用")
            @RequestParam String status) {
        Integer statusCode = "启用".equals(status) ? 1 : 0;
        return roleService.toggleStatus(roleId, statusCode);
    }
}

