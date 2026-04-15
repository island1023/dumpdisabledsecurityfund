package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.EmployeeService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/employee")
public class EmployeeController {
    @Resource
    private EmployeeService employeeService;

    @PostMapping("/importDisabled")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> importDisabled(MultipartFile file) {
        return employeeService.importDisabled(file);
    }

    @PostMapping("/importNormal")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> importNormal(MultipartFile file) {
        return employeeService.importNormal(file);
    }
}
