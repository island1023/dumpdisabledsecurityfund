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
import java.util.Map;

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
        System.out.println("\n\n========================================");
        System.out.println("=== SystemUserController.importExcel 被调用 ===");
        System.out.println("=== 请求方法: POST ===");
        System.out.println("=== Content-Type: " + (file != null ? file.getContentType() : "N/A"));
        System.out.println("=== 文件名: " + (file != null ? file.getOriginalFilename() : "null"));
        System.out.println("=== 文件大小: " + (file != null ? file.getSize() : 0) + " bytes");
        System.out.println("=== 文件是否为空: " + (file != null ? file.isEmpty() : "N/A"));
        System.out.println("========================================\n");

        if (file == null) {
            System.err.println("❌ 错误: file参数为null，前端可能没有正确发送文件");
            return Result.error("文件不能为空，请检查前端是否正确上传文件");
        }

        if (file.isEmpty()) {
            System.err.println("❌ 错误: 文件内容为空，文件大小为0");
            return Result.error("文件内容为空，请选择有效的Excel文件");
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || (!originalFilename.endsWith(".xlsx") && !originalFilename.endsWith(".xls"))) {
            System.err.println("❌ 错误: 文件格式不正确，文件名: " + originalFilename);
            return Result.error("请上传.xls或.xlsx格式的Excel文件");
        }

        try {
            System.out.println("✅ 文件验证通过，开始调用Service层处理...");
            Result<?> result = sysUserService.importExcel(file);
            System.out.println("✅ Service层处理完成，返回结果: " + result.getMessage());
            return result;
        } catch (org.springframework.web.multipart.MultipartException e) {
            System.err.println("\n\n❌❌❌ Multipart解析异常 ❌❌❌");
            System.err.println("异常类型: " + e.getClass().getName());
            System.err.println("异常消息: " + e.getMessage());
            e.printStackTrace();
            System.err.println("可能原因:");
            System.err.println("1. 前端发送的multipart格式不正确");
            System.err.println("2. Content-Type配置冲突");
            System.err.println("3. 文件大小超出限制");
            System.err.println("建议: 检查前端HttpUtil的multiFormDataList配置\n");
            return Result.error("文件上传格式错误: " + e.getMessage());
        } catch (IllegalArgumentException e) {
            System.err.println("\n\n❌❌❌ 参数异常 ❌❌❌");
            System.err.println("异常消息: " + e.getMessage());
            e.printStackTrace();
            return Result.error("参数错误: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("\n\n❌❌❌ 未预期的系统异常 ❌❌❌");
            System.err.println("异常类型: " + e.getClass().getName());
            System.err.println("异常消息: " + e.getMessage());
            System.err.println("完整堆栈跟踪:");
            e.printStackTrace();
            System.err.println("\n建议排查步骤:");
            System.err.println("1. 检查Excel文件格式是否正确");
            System.err.println("2. 检查数据库连接是否正常");
            System.err.println("3. 检查是否有权限问题");
            System.err.println("4. 查看上方堆栈信息定位具体代码行\n");
            return Result.error("系统异常，导入失败: " + e.getMessage());
        }
    }

    @Operation(summary = "测试文件上传", description = "用于调试文件上传功能")
    @PostMapping("/test-upload")
    public Result<?> testUpload(@RequestParam("file") MultipartFile file) {
        System.out.println("\n\n========== 测试上传接口 ==========");
        System.out.println("file 是否为 null: " + (file == null));
        if (file != null) {
            System.out.println("文件名: " + file.getOriginalFilename());
            System.out.println("文件大小: " + file.getSize());
            System.out.println("Content-Type: " + file.getContentType());
            System.out.println("参数名: file");
        }
        System.out.println("====================================\n\n");

        if (file == null) {
            return Result.error("file参数为null");
        }
        if (file.isEmpty()) {
            return Result.error("文件为空");
        }
        return Result.success("文件接收成功", Map.of(
                "filename", file.getOriginalFilename(),
                "size", file.getSize(),
                "contentType", file.getContentType()
        ));
    }
}
