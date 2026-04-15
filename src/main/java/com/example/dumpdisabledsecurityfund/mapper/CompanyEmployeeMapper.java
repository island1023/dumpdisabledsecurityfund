package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CompanyEmployee;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CompanyEmployeeMapper {
    int insert(CompanyEmployee employee);

    int countActiveByCompanyId(Long companyId);

    CompanyEmployee selectById(@Param("id") Long id);

    List<CompanyEmployee> selectByCompanyId(@Param("companyId") Long companyId);

    List<CompanyEmployee> selectByCompanyIdAndStatus(@Param("companyId") Long companyId, @Param("isActive") Integer isActive);

    int updateById(CompanyEmployee employee);

    int deleteById(@Param("id") Long id);

    int deleteByCompanyId(@Param("companyId") Long companyId);
}
