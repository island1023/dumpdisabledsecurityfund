package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Role;
import com.example.dumpdisabledsecurityfund.mapper.RoleMapper;
import com.example.dumpdisabledsecurityfund.service.RoleService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class RoleServiceImpl implements RoleService {
    @Resource
    private RoleMapper roleMapper;

    @Override
    public Result<?> list() {
        List<Role> roles = roleMapper.selectAll();
        return Result.success(roles);
    }

    @Override
    public Result<?> listWithKeyword(String keyword) {
        List<Role> roles = roleMapper.selectAll();

        if (keyword != null && !keyword.trim().isEmpty()) {
            String lowerKeyword = keyword.toLowerCase();
            roles = roles.stream()
                    .filter(role ->
                            (role.getRoleName() != null && role.getRoleName().toLowerCase().contains(lowerKeyword)) ||
                                    (role.getRoleCode() != null && role.getRoleCode().toLowerCase().contains(lowerKeyword))
                    )
                    .collect(Collectors.toList());
        }

        return Result.success(roles);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "创建角色", table = "role")
    public Result<?> create(Role role) {
        if (role == null || role.getRoleCode() == null || role.getRoleName() == null) {
            return Result.error("role_name and role_code are required");
        }
        Role old = roleMapper.selectByCode(role.getRoleCode());
        if (old != null) {
            return Result.error("role_code already exists");
        }
        role.setCreateTime(DateUtil.now());
        role.setUpdateTime(DateUtil.now());
        roleMapper.insert(role);
        return Result.success(role);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "更新角色", table = "role")
    public Result<?> update(Role role) {
        if (role == null || role.getId() == null) {
            return Result.error("id is required");
        }
        Role db = roleMapper.selectById(role.getId());
        if (db == null) {
            return Result.error("role not found");
        }
        Role codeConflict = roleMapper.selectByCode(role.getRoleCode());
        if (codeConflict != null && !codeConflict.getId().equals(role.getId())) {
            return Result.error("role_code already exists");
        }
        role.setUpdateTime(DateUtil.now());
        roleMapper.updateById(role);
        return Result.success(role);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "删除角色", table = "role")
    public Result<?> delete(Long id) {
        if (id == null) {
            return Result.error("id is required");
        }
        int rows = roleMapper.deleteById(id);
        if (rows == 0) {
            return Result.error("role not found");
        }
        return Result.success();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "切换角色状态", table = "role")
    public Result<?> toggleStatus(Long id, Integer status) {
        Role role = roleMapper.selectById(id);
        if (role == null) {
            return Result.error("角色不存在");
        }

        role.setStatus(status);
        role.setUpdateTime(DateUtil.now());
        roleMapper.updateById(role);

        return Result.success("操作成功");
    }
}
