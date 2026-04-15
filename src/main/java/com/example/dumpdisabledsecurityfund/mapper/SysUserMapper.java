package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.SysUser;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface SysUserMapper {
    int insert(SysUser sysUser);

    SysUser selectById(@Param("id") Long id);

    SysUser selectByUsername(@Param("username") String username);

    List<SysUser> selectAll();

    List<SysUser> selectByUserType(@Param("userType") Integer userType);

    List<SysUser> selectByRegionId(@Param("regionId") Long regionId);

    List<SysUser> selectByStatus(@Param("status") Integer status);

    int updateById(SysUser sysUser);

    int updateLastLoginTime(@Param("id") Long id, @Param("loginTime") String loginTime, @Param("updateTime") String updateTime);

    int deleteById(@Param("id") Long id);
}
