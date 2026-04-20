package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.UserRole;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface UserRoleMapper {
    int insert(UserRole userRole);

    UserRole selectById(@Param("id") Long id);

    List<UserRole> selectByUserId(@Param("userId") Long userId);

    List<String> selectRoleCodesByUserId(@Param("userId") Long userId);

    List<Long> selectRoleIdsByUserId(@Param("userId") Long userId);

    List<UserRole> selectByRoleId(@Param("roleId") Long roleId);

    int batchInsert(List<UserRole> userRoles);

    int deleteByUserId(@Param("userId") Long userId);

    int deleteByUserIdAndRoleId(@Param("userId") Long userId, @Param("roleId") Long roleId);

    int deleteByRoleId(@Param("roleId") Long roleId);
}
