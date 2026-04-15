package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Role;
import com.example.dumpdisabledsecurityfund.service.RoleService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/role")
public class RoleController {
    @Resource
    private RoleService roleService;

    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> list() {
        return roleService.list();
    }

    @PostMapping("/create")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> create(@RequestBody Role role) {
        return roleService.create(role);
    }

    @PutMapping("/update")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> update(@RequestBody Role role) {
        return roleService.update(role);
    }

    @DeleteMapping("/delete")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> delete(@RequestParam Long id) {
        return roleService.delete(id);
    }
}
