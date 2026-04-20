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
        user.setUsername(dto.getUsername());
        user.setRealName(dto.getRealName());
        user.setPassword(PasswordUtil.encrypt("123456"));
        user.setStatus(1);
        
        // 转换角色编码为userType和adminLevel
        convertRoleToUserType(dto.getRole(), user);
        
        // 处理地区
        if (dto.getDistrict() != null && !dto.getDistrict().isEmpty()) {
            Region region = regionMapper.selectByName(dto.getDistrict());
            if (region != null) {
                user.setRegionId(region.getId());
            }
        }
        
        user.setCreateTime(DateUtil.now());
        user.setUpdateTime(DateUtil.now());

        sysUserMapper.insert(user);

        Map<String, Object> data = new HashMap<>();
        data.put("id", String.valueOf(user.getId()));
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

        user.setUsername(dto.getUsername());
        user.setRealName(dto.getRealName());
        convertRoleToUserType(dto.getRole(), user);
        
        if (dto.getDistrict() != null && !dto.getDistrict().isEmpty()) {
            Region region = regionMapper.selectByName(dto.getDistrict());
            if (region != null) {
                user.setRegionId(region.getId());
            }
        } else {
            user.setRegionId(null);
        }
        
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
        vo.setId(String.valueOf(user.getId()));
        vo.setUsername(user.getUsername());
        vo.setRealName(user.getRealName());
        vo.setRole(convertToRoleCode(user));
        vo.setRoleName(convertToRoleName(user));
        
        if (user.getRegionId() != null) {
            Region region = regionMapper.selectById(user.getRegionId());
            if (region != null) {
                vo.setDistrictCode(region.getCode());
                vo.setDistrictName(region.getName());
            }
        } else {
            vo.setDistrictCode("");
            vo.setDistrictName("");
        }
        
        vo.setStatus(user.getStatus() == 1 ? "启用" : "禁用");
        vo.setCreateTime(user.getCreateTime() != null ? user.getCreateTime().substring(0, 10) : "");
        vo.setUpdateTime(user.getUpdateTime() != null ? user.getUpdateTime().substring(0, 10) : "");

        return vo;
    }

    private String convertToRoleCode(SysUser user) {
        if (user.getUserType() != null && user.getUserType() == 2) {
            if (user.getAdminLevel() != null) {
                switch (user.getAdminLevel()) {
                    case 2: return "CITY_LEADER";
                    case 3: return "DISTRICT_LEADER";
                    default: return "DISTRICT_LEADER";
                }
            }
            return "DISTRICT_LEADER";
        }
        
        if (user.getAdminLevel() != null) {
            switch (user.getAdminLevel()) {
                case 1: return "SYSTEM_ADMIN";
                case 2: return "CITY_ADMIN";
                case 3: return "DISTRICT_ADMIN";
                default: return "SYSTEM_ADMIN";
            }
        }
        return "SYSTEM_ADMIN";
    }

    private String convertToRoleName(SysUser user) {
        String roleCode = convertToRoleCode(user);
        switch (roleCode) {
            case "SYSTEM_ADMIN": return "系统管理员";
            case "CITY_ADMIN": return "市级管理员";
            case "DISTRICT_ADMIN": return "区级管理员";
            case "CITY_LEADER": return "市级领导";
            case "DISTRICT_LEADER": return "区级领导";
            default: return "未知角色";
        }
    }

    private void convertRoleToUserType(String role, SysUser user) {
        switch (role) {
            case "SYSTEM_ADMIN":
                user.setUserType(1);
                user.setAdminLevel(1);
                break;
            case "CITY_ADMIN":
                user.setUserType(1);
                user.setAdminLevel(2);
                break;
            case "DISTRICT_ADMIN":
                user.setUserType(1);
                user.setAdminLevel(3);
                break;
            case "CITY_LEADER":
                user.setUserType(2);
                user.setAdminLevel(2);
                break;
            case "DISTRICT_LEADER":
                user.setUserType(2);
                user.setAdminLevel(3);
                break;
            case "UNIT":
                user.setUserType(1);
                user.setAdminLevel(null);
                break;
            default:
                user.setUserType(1);
                user.setAdminLevel(1);
        }
    }
}
