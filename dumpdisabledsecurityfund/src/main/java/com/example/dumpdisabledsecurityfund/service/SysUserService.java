package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.SysUserCreateDTO;
import com.example.dumpdisabledsecurityfund.dto.SysUserUpdateDTO;
import org.springframework.web.multipart.MultipartFile;

public interface SysUserService {
    Result<?> list(String keyword, Integer pageNum, Integer pageSize);

    Result<?> create(SysUserCreateDTO dto);

    Result<?> update(SysUserUpdateDTO dto);

    Result<?> delete(Long id);

    Result<?> toggleStatus(Long id, Integer status);

    Result<?> resetPassword(Long id);

    Result<?> importExcel(MultipartFile file);
}
