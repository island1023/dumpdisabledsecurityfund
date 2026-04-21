package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.Role;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface RoleMapper {
    int insert(Role role);

    Role selectById(@Param("id") Long id);

    Role selectByRoleCode(@Param("roleCode") String roleCode);

    Role selectByCode(@Param("roleCode") String roleCode);

    List<Role> selectAll();

    List<Role> selectByRoleType(@Param("roleType") Integer roleType);

    int updateById(Role role);

    int deleteById(@Param("id") Long id);
}
