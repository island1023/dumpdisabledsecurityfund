package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.ImportService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/import")
public class ImportController {
    @Resource
    private ImportService importService;

    @PostMapping("/importAll")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> importAll(@RequestParam("file") MultipartFile file, @RequestParam String type) {
        return importService.importAll(file, type);
    }
}
