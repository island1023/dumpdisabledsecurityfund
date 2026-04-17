package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.SysUserCreateDTO;
import com.example.dumpdisabledsecurityfund.dto.SysUserUpdateDTO;
import com.example.dumpdisabledsecurityfund.entity.Region;
import com.example.dumpdisabledsecurityfund.entity.SysUser;
import com.example.dumpdisabledsecurityfund.mapper.RegionMapper;
import com.example.dumpdisabledsecurityfund.mapper.SysUserMapper;
import com.example.dumpdisabledsecurityfund.service.SysUserService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import com.example.dumpdisabledsecurityfund.util.PasswordUtil;
import com.example.dumpdisabledsecurityfund.vo.ResetPasswordVO;
import com.example.dumpdisabledsecurityfund.vo.SysUserVO;
import jakarta.annotation.Resource;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SysUserServiceImpl implements SysUserService {
    @Resource
    private SysUserMapper sysUserMapper;

    @Resource
    private RegionMapper regionMapper;

    @Override
    public Result<?> list(String keyword, Integer pageNum, Integer pageSize) {
        if (pageNum == null || pageNum < 1) pageNum = 1;
        if (pageSize == null || pageSize < 1) pageSize = 20;

        int offset = (pageNum - 1) * pageSize;
        List<SysUser> users = sysUserMapper.selectUsersWithPage(keyword, offset, pageSize);
        long total = sysUserMapper.countUsers(keyword);

        List<SysUserVO> voList = users.stream().map(this::convertToVO).collect(Collectors.toList());
        PageResult<SysUserVO> pageResult = PageResult.build(total, pageNum, pageSize, voList);

        return Result.success(pageResult);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "创建系统用户", table = "sys_user")
    public Result<?> create(SysUserCreateDTO dto) {
        SysUser existingUser = sysUserMapper.selectByUsername(dto.getUsername());
        if (existingUser != null) {
            return Result.error("用户名已存在");
        }

        SysUser user = new SysUser();
        BeanUtils.copyProperties(dto, user);
        user.setPassword(PasswordUtil.encrypt("123456"));
        user.setStatus(1);
        user.setCreateTime(DateUtil.now());
        user.setUpdateTime(DateUtil.now());

        sysUserMapper.insert(user);

        Map<String, Object> data = new HashMap<>();
        data.put("id", user.getId());
        data.put("username", user.getUsername());
        data.put("password", "123456");

        return Result.success("创建成功", data);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "更新系统用户", table = "sys_user")
    public Result<?> update(SysUserUpdateDTO dto) {
        SysUser user = sysUserMapper.selectById(dto.getId());
        if (user == null) {
            return Result.error("用户不存在");
        }

        BeanUtils.copyProperties(dto, user);
        user.setUpdateTime(DateUtil.now());

        sysUserMapper.updateById(user);
        return Result.success("更新成功");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "删除系统用户", table = "sys_user")
    public Result<?> delete(Long id) {
        SysUser user = sysUserMapper.selectById(id);
        if (user == null) {
            return Result.error("用户不存在");
        }

        sysUserMapper.deleteById(id);
        return Result.success("删除成功");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "切换用户状态", table = "sys_user")
    public Result<?> toggleStatus(Long id, Integer status) {
        SysUser user = sysUserMapper.selectById(id);
        if (user == null) {
            return Result.error("用户不存在");
        }

        user.setStatus(status);
        user.setUpdateTime(DateUtil.now());
        sysUserMapper.updateById(user);

        return Result.success("操作成功");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "重置用户密码", table = "sys_user")
    public Result<?> resetPassword(Long id) {
        SysUser user = sysUserMapper.selectById(id);
        if (user == null) {
            return Result.error("用户不存在");
        }

        String newPassword = "123456";
        String encryptedPassword = PasswordUtil.encrypt(newPassword);
        sysUserMapper.updatePassword(id, encryptedPassword, DateUtil.now());

        ResetPasswordVO vo = new ResetPasswordVO();
        vo.setNewPassword(newPassword);

        return Result.success("密码重置成功", vo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入系统用户", table = "sys_user")
    public Result<?> importExcel(MultipartFile file) {
        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            int successCount = 0;
            int failCount = 0;
            List<Map<String, Object>> errors = new ArrayList<>();

            for (int i = 0; i < list.size(); i++) {
                List<String> row = list.get(i);
                if (row.size() < 4) {
                    failCount++;
                    continue;
                }

                try {
                    SysUser user = new SysUser();
                    user.setUsername(row.get(0));
                    user.setPassword(PasswordUtil.encrypt(row.get(1)));
                    user.setRealName(row.get(2));
                    user.setUserType(Integer.parseInt(row.get(3)));
                    user.setStatus(1);
                    user.setCreateTime(DateUtil.now());
                    user.setUpdateTime(DateUtil.now());

                    sysUserMapper.insert(user);
                    successCount++;
                } catch (Exception e) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("username", row.get(0));
                    error.put("message", e.getMessage());
                    errors.add(error);
                }
            }

            Map<String, Object> data = new HashMap<>();
            data.put("successCount", successCount);
            data.put("failCount", failCount);
            data.put("errors", errors);

            return Result.success("导入完成", data);
        } catch (Exception e) {
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }

    private SysUserVO convertToVO(SysUser user) {
        SysUserVO vo = new SysUserVO();
        BeanUtils.copyProperties(user, vo);

        if (user.getUserType() != null) {
            vo.setUserTypeName(user.getUserType() == 1 ? "管理员" : "领导");
        }

        if (user.getAdminLevel() != null) {
            switch (user.getAdminLevel()) {
                case 1: vo.setAdminLevelName("系统管理员"); break;
                case 2: vo.setAdminLevelName("市级管理员"); break;
                case 3: vo.setAdminLevelName("区县管理员"); break;
            }
        }

        if (user.getStatus() != null) {
            vo.setStatusName(user.getStatus() == 1 ? "启用" : "禁用");
        }

        if (user.getRegionId() != null) {
            Region region = regionMapper.selectById(user.getRegionId());
            if (region != null) {
                vo.setRegionName(region.getName());
            }
        }

        return vo;
    }
}
