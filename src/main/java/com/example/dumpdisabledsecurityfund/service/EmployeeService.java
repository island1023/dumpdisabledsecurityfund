package com.example.dumpdisabledsecurityfund.service;
import com.example.dumpdisabledsecurityfund.common.Result;
import org.springframework.web.multipart.MultipartFile;

public interface EmployeeService {
    Result<?> importDisabled(MultipartFile file);
    Result<?> importNormal(MultipartFile file);
}