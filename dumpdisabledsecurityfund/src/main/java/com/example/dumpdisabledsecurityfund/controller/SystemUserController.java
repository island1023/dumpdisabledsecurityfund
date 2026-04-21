package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.SysUserCreateDTO;
import com.example.dumpdisabledsecurityfund.dto.SysUserUpdateDTO;
import com.example.dumpdisabledsecurityfund.service.SysUserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "系统用户管理(PDF规范)", description = "符合PDF文档规范的系统用户管理接口")
@RestController
@RequestMapping("/system/users")
public class SystemUserController {
    @Resource
    private SysUserService sysUserService;

    @Operation(summary = "获取用户列表", description = "获取系统用户列表，支持关键词搜索和分页")
    @GetMapping
    @RequirePermission(roles = {"admin_system"})
    public Result<?> list(
            @Parameter(description = "搜索关键词（匹配username或realName）", example = "admin")
            @RequestParam(required = false) String keyword,
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize) {
        return sysUserService.list(keyword, page, pageSize);
    }

    @Operation(summary = "新增用户", description = "创建系统用户账号，自动生成初始密码123456")
    @PostMapping
    @RequirePermission(roles = {"admin_system"})
    public Result<?> create(
            @Parameter(description = "用户信息", required = true)
            @Valid @RequestBody SysUserCreateDTO dto) {
        return sysUserService.create(dto);
    }

    @Operation(summary = "编辑用户", description = "修改用户基本信息")
    @PutMapping("/{userId}")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> update(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long userId,
            @Parameter(description = "用户信息", required = true)
            @Valid @RequestBody SysUserUpdateDTO dto) {
        dto.setId(userId);
        return sysUserService.update(dto);
    }

    @Operation(summary = "删除用户", description = "根据ID删除用户")
    @DeleteMapping("/{userId}")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> delete(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long userId) {
        return sysUserService.delete(userId);
    }

    @Operation(summary = "切换用户状态", description = "启用或禁用用户账号")
    @PutMapping("/{userId}/status")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> toggleStatus(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long userId,
            @Parameter(description = "目标状态：启用或禁用", required = true, example = "启用")
            @RequestParam String status) {
        Integer statusCode = "启用".equals(status) ? 1 : 0;
        return sysUserService.toggleStatus(userId, statusCode);
    }

    @Operation(summary = "重置密码", description = "将用户密码重置为123456")
    @PutMapping("/{userId}/reset-password")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> resetPassword(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long userId) {
        return sysUserService.resetPassword(userId);
    }

    @Operation(summary = "Excel批量导入用户", description = "通过Excel文件批量导入系统用户账号")
    @PostMapping("/import")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> importExcel(
            @Parameter(description = "Excel文件（.xls/.xlsx格式）", required = true)
            @RequestParam("file") MultipartFile file) {
        return sysUserService.importExcel(file);
    }
}
