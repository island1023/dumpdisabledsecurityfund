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

@Tag(name = "角色管理", description = "系统角色的增删改查功能")
@RestController
@RequestMapping("/role")
public class RoleController {
    @Resource
    private RoleService roleService;

    @Operation(summary = "查询角色列表", description = "获取系统中所有的角色信息")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> list() {
        return roleService.list();
    }

    @Operation(summary = "创建角色", description = "新增一个系统角色，设置角色名称、编码和描述")
    @PostMapping("/create")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> create(
            @Parameter(description = "角色信息", required = true)
            @RequestBody Role role) {
        return roleService.create(role);
    }

    @Operation(summary = "更新角色", description = "修改已有角色的信息")
    @PutMapping("/update")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> update(
            @Parameter(description = "角色信息（需包含ID）", required = true)
            @RequestBody Role role) {
        return roleService.update(role);
    }

    @Operation(summary = "删除角色", description = "根据ID删除指定的角色")
    @DeleteMapping("/delete")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> delete(
            @Parameter(description = "角色ID", required = true, example = "1")
            @RequestParam Long id) {
        return roleService.delete(id);
    }

    @Operation(summary = "切换角色状态", description = "启用或禁用角色")
    @PutMapping("/status/{id}")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> toggleStatus(
            @Parameter(description = "角色ID", required = true, example = "1")
            @PathVariable Long id,
            @Parameter(description = "目标状态：0-禁用，1-启用", required = true, example = "1")
            @RequestParam Integer status) {
        return roleService.toggleStatus(id, status);
    }
}
