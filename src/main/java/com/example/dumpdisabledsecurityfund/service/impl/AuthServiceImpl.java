package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.CaptchaStore;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.LoginDTO;
import com.example.dumpdisabledsecurityfund.entity.CompanyUser;
import com.example.dumpdisabledsecurityfund.entity.SysUser;
import com.example.dumpdisabledsecurityfund.mapper.CompanyUserMapper;
import com.example.dumpdisabledsecurityfund.mapper.SysUserMapper;
import com.example.dumpdisabledsecurityfund.mapper.UserRoleMapper;
import com.example.dumpdisabledsecurityfund.service.AuthService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.JwtUtil;
import com.example.dumpdisabledsecurityfund.util.PasswordUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class AuthServiceImpl implements AuthService {
    @Resource
    private CompanyUserMapper companyUserMapper;
    @Resource
    private SysUserMapper sysUserMapper;
    @Resource
    private UserRoleMapper userRoleMapper;
    @Resource
    private CaptchaStore captchaStore;

    @Override
    public Result<?> captcha() {
        return Result.success(captchaStore.create());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> login(LoginDTO dto) {
        if (dto == null || dto.getUsername() == null || dto.getPassword() == null) {
            return Result.error("username and password are required");
        }
        if (!captchaStore.validate(dto.getCaptchaKey(), dto.getCaptchaCode())) {
            return Result.error("captcha invalid or expired");
        }

        SysUser sysUser = sysUserMapper.selectByUsername(dto.getUsername());
        if (sysUser != null) {
            return loginSystemUser(sysUser, dto.getPassword());
        }

        CompanyUser companyUser = companyUserMapper.selectByUsername(dto.getUsername());
        if (companyUser != null) {
            return loginCompanyUser(companyUser, dto.getPassword());
        }
        return Result.error("account not found");
    }

    private Result<?> loginSystemUser(SysUser user, String password) {
        if (!passwordMatches(user.getPassword(), password)) {
            return Result.error("password incorrect");
        }
        if (user.getStatus() == 0) {
            return Result.error("account disabled");
        }

        List<String> roleCodes = userRoleMapper.selectRoleCodesByUserId(user.getId());
        if (roleCodes == null) {
            roleCodes = new ArrayList<>();
        }
        if (roleCodes.isEmpty()) {
            roleCodes.add(user.getUserType() != null && user.getUserType() == 2 ? "leader_default" : "admin_default");
        }

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.getId());
        claims.put("username", user.getUsername());
        claims.put("accountType", "sys");
        claims.put("roleCodes", roleCodes);
        String token = JwtUtil.createToken(claims);

        String now = DateUtil.now();
        sysUserMapper.updateLastLoginTime(user.getId(), now, now);

        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("accountType", "sys");
        result.put("userId", user.getId());
        result.put("username", user.getUsername());
        result.put("realName", user.getRealName());
        result.put("roleCodes", roleCodes);
        result.put("dataScope", resolveDataScope(user));
        result.put("menus", buildMenus(roleCodes, user.getUserType()));
        result.put("readOnly", user.getUserType() != null && user.getUserType() == 2);
        return Result.success(result);
    }

    private Result<?> loginCompanyUser(CompanyUser user, String password) {
        if (!passwordMatches(user.getPassword(), password)) {
            return Result.error("password incorrect");
        }
        if (user.getStatus() == 0) {
            return Result.error("account disabled");
        }

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.getId());
        claims.put("companyId", user.getCompanyId());
        claims.put("username", user.getUsername());
        claims.put("accountType", "company");
        String token = JwtUtil.createToken(claims);

        String now = DateUtil.now();
        companyUserMapper.updateLastLoginTime(user.getId(), now, now);

        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("accountType", "company");
        result.put("userId", user.getId());
        result.put("companyId", user.getCompanyId());
        result.put("username", user.getUsername());
        result.put("realName", user.getName());
        result.put("roleCodes", List.of("company_user"));
        result.put("dataScope", "COMPANY");
        result.put("menus", List.of("companyArchive", "employeeManage", "reductionApply", "notice"));
        result.put("readOnly", false);
        return Result.success(result);
    }

    private boolean passwordMatches(String savedPassword, String rawPassword) {
        if (savedPassword == null) {
            return false;
        }
        return savedPassword.equals(rawPassword) || savedPassword.equals(PasswordUtil.encrypt(rawPassword));
    }

    private String resolveDataScope(SysUser user) {
        if (user.getUserType() != null && user.getUserType() == 2) {
            return user.getRegionId() == null ? "CITY" : "DISTRICT";
        }
        if (user.getAdminLevel() == null) {
            return "SYSTEM";
        }
        if (user.getAdminLevel() == 1 || user.getAdminLevel() == 2) {
            return "CITY";
        }
        return "DISTRICT";
    }

    private List<String> buildMenus(List<String> roleCodes, Integer userType) {
        if (userType != null && userType == 2) {
            return List.of("dashboard", "statisticsReport", "fundUsageSupervision", "notice");
        }

        List<String> menus = new ArrayList<>();
        menus.add("dashboard");
        if (roleCodes.stream().anyMatch(code -> code.contains("system") || code.contains("admin"))) {
            menus.add("systemManage");
            menus.add("rolePermission");
            menus.add("region");
            menus.add("importCenter");
        }
        menus.add("companyArchive");
        menus.add("employeeManage");
        menus.add("calculation");
        menus.add("paymentVerify");
        menus.add("reductionAudit");
        menus.add("notice");
        menus.add("statisticsReport");
        return menus;
    }
}

