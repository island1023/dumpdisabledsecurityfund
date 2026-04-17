package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.ChangePasswordDTO;
import com.example.dumpdisabledsecurityfund.dto.LoginDTO;
import com.example.dumpdisabledsecurityfund.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@Tag(name = "用户认证", description = "用户登录、验证码生成及密码管理")
@RestController
@RequestMapping("/auth")
public class AuthController {
    @Resource
    private AuthService authService;

    @Operation(summary = "获取验证码", description = "生成4位数字图形验证码")
    @PostMapping("/captcha")
    public Result<?> captcha() {
        return authService.captcha();
    }

    @Operation(summary = "用户登录", description = "验证用户名、密码和验证码")
    @PostMapping("/login")
    public Result<?> login(
            @Parameter(description = "登录信息", required = true)
            @Valid @RequestBody LoginDTO dto) {
        return authService.login(dto);
    }

    @Operation(summary = "修改个人信息", description = "用户修改自己的基本信息")
    @PutMapping("/profile")
    @RequirePermission(requireLogin = true)
    public Result<?> updateProfile(
            @Parameter(description = "用户信息", required = true)
            @RequestBody Object profile) {
        return authService.updateProfile(profile);
    }

    @Operation(summary = "修改密码", description = "用户修改自己的密码，需验证旧密码")
    @PutMapping("/change-password")
    @RequirePermission(requireLogin = true)
    public Result<?> changePassword(
            @Parameter(description = "用户ID", required = true, example = "1")
            @RequestParam Long userId,
            @Parameter(description = "账户类型：sys/company", required = true, example = "sys")
            @RequestParam String accountType,
            @Parameter(description = "修改密码信息", required = true)
            @Valid @RequestBody ChangePasswordDTO dto) {
        return authService.changePassword(userId, accountType, dto);
    }
}
