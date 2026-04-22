package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.*;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.Locale;

@Service
public class ImportServiceImpl implements ImportService {
    @Resource
    private CompanyService companyService;
    @Resource
    private EmployeeService employeeService;
    @Resource
    private SysUserService sysUserService;
    @Resource
    private PaymentService paymentService;
    @Resource
    private FundUsageService fundUsageService;

    @Override
    public Result<?> importAll(MultipartFile file, String type) {
        if (file == null || file.isEmpty()) {
            return Result.error("file is required");
        }
        if (type == null || type.isBlank()) {
            return Result.error("type is required");
        }

        String t = type.trim().toLowerCase(Locale.ROOT);
        return switch (t) {
            case "company" -> companyService.importExcel(file);
            case "employee_disabled", "disabled_employee" -> employeeService.importDisabled(file);
            case "employee_normal", "normal_employee" -> employeeService.importNormal(file);
            case "all_employees", "unit_employees" -> employeeService.importAllEmployees(file);
            case "sys_user", "admin_user" -> sysUserService.importExcel(file);
            case "tax", "tax_data", "payable" -> paymentService.importTaxData(file);
            case "fund_usage" -> fundUsageService.importExcel(file);
            default -> Result.error("unsupported import type: " + type);
        };
    }
}