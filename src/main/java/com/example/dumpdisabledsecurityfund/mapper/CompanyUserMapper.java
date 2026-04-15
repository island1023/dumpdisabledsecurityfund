package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CompanyUser;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CompanyUserMapper {
    int insert(CompanyUser user);

    CompanyUser selectById(@Param("id") Long id);

    CompanyUser selectByUsername(@Param("username") String username);

    List<CompanyUser> selectByCompanyId(@Param("companyId") Long companyId);

    List<CompanyUser> selectByCompanyIdAndStatus(@Param("companyId") Long companyId, @Param("status") Integer status);

    int updateById(CompanyUser user);

    int updateLastLoginTime(@Param("id") Long id, @Param("loginTime") String loginTime, @Param("updateTime") String updateTime);

    int deleteById(@Param("id") Long id);

    int deleteByCompanyId(@Param("companyId") Long companyId);
}
