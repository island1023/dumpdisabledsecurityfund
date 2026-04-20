package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * 缴费控制器
 */
@Tag(name = "缴费管理", description = "税务缴费数据的导入和管理")
@RestController
@RequestMapping("/payment")
public class PaymentController {
    @Resource
    private PaymentService paymentService;

    @Operation(summary = "导入税务缴费数据", description = "通过Excel文件批量导入企业的税务缴费记录，用于核对残保金缴纳情况")
    @PostMapping("/importTaxData")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> importTaxData(
            @Parameter(description = "Excel文件，包含企业名称、统一社会信用代码、缴费年度、缴费金额等信息", required = true)
            MultipartFile file) {
        return paymentService.importTaxData(file);
    }
}

