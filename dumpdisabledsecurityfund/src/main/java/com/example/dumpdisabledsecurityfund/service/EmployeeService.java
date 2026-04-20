package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;
import org.springframework.web.multipart.MultipartFile;

public interface EmployeeService {
    Result<?> importDisabled(MultipartFile file);

    Result<?> importNormal(MultipartFile file);

    Result<?> getAllEmployees(Integer page, Integer pageSize);

    Result<?> getDisabledEmployees();

    Result<?> getDisabledEmployeeDetail(Long employeeId);

    Result<?> getNonDisabledEmployees();

    Result<?> addEmployee(Object request);

    Result<?> addDisabledEmployees(Object request);
}
