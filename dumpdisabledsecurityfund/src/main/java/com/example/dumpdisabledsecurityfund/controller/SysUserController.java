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

@Tag(name = "系统用户管理", description = "系统用户的增删改查和导入功能")
@RestController
@RequestMapping("/sysUser")
public class SysUserController {
    @Resource
    private SysUserService sysUserService;

    @Operation(summary = "查询用户列表", description = "获取系统用户列表，支持关键词搜索和分页")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> list(
            @Parameter(description = "搜索关键词（匹配用户名或姓名）", example = "admin")
            @RequestParam(required = false) String keyword,
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer pageNum,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize) {
        return sysUserService.list(keyword, pageNum, pageSize);
    }

    @Operation(summary = "创建用户", description = "新增系统用户账号，自动生成初始密码123456")
    @PostMapping("/create")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> create(
            @Parameter(description = "用户信息", required = true)
            @Valid @RequestBody SysUserCreateDTO dto) {
        return sysUserService.create(dto);
    }

    @Operation(summary = "更新用户", description = "修改用户基本信息")
    @PutMapping("/update")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> update(
            @Parameter(description = "用户信息", required = true)
            @Valid @RequestBody SysUserUpdateDTO dto) {
        return sysUserService.update(dto);
    }

    @Operation(summary = "删除用户", description = "根据ID删除用户")
    @DeleteMapping("/delete/{id}")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> delete(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long id) {
        return sysUserService.delete(id);
    }

    @Operation(summary = "切换用户状态", description = "启用或禁用用户账号")
    @PutMapping("/status/{id}")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> toggleStatus(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long id,
            @Parameter(description = "目标状态：0-禁用，1-启用", required = true, example = "1")
            @RequestParam Integer status) {
        return sysUserService.toggleStatus(id, status);
    }

    @Operation(summary = "重置密码", description = "将用户密码重置为123456")
    @PostMapping("/reset-password/{id}")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> resetPassword(
            @Parameter(description = "用户ID", required = true, example = "1")
            @PathVariable Long id) {
        return sysUserService.resetPassword(id);
    }

    @Operation(summary = "导入系统用户", description = "通过Excel文件批量导入系统用户账号")
    @PostMapping("/importExcel")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> importExcel(
            @Parameter(description = "Excel文件", required = true)
            MultipartFile file) {
        return sysUserService.importExcel(file);
    }
}
