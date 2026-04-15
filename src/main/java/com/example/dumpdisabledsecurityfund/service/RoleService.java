package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Role;

public interface RoleService {
    Result<?> list();

    Result<?> create(Role role);

    Result<?> update(Role role);

    Result<?> delete(Long id);
}
