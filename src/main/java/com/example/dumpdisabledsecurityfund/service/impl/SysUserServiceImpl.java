package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.SysUser;
import com.example.dumpdisabledsecurityfund.mapper.SysUserMapper;
import com.example.dumpdisabledsecurityfund.service.SysUserService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import com.example.dumpdisabledsecurityfund.util.PasswordUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Service
public class SysUserServiceImpl implements SysUserService {
    @Resource
    private SysUserMapper sysUserMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入系统用户", table = "sys_user")
    public Result<?> importExcel(MultipartFile file) {
        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            for (List<String> row : list) {
                if (row.size() < 4) {
                    continue;
                }
                SysUser user = new SysUser();
                user.setUsername(row.get(0));
                user.setPassword(PasswordUtil.encrypt(row.get(1)));
                user.setRealName(row.get(2));
                user.setUserType(Integer.parseInt(row.get(3)));
                user.setStatus(1);
                user.setCreateTime(DateUtil.now());
                user.setUpdateTime(DateUtil.now());
                sysUserMapper.insert(user);
            }
            return Result.success("sys user import completed");
        } catch (Exception e) {
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }
}
