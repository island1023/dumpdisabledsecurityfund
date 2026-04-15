package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CompanyDisabledEmployee;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CompanyDisabledEmployeeMapper {
    int insert(CompanyDisabledEmployee employee);

    int countActiveByCompanyId(Long companyId);

    CompanyDisabledEmployee selectById(@Param("id") Long id);

    List<CompanyDisabledEmployee> selectByCompanyId(@Param("companyId") Long companyId);

    List<CompanyDisabledEmployee> selectByCompanyIdAndStatus(@Param("companyId") Long companyId, @Param("isActive") Integer isActive);

    CompanyDisabledEmployee selectByIdCard(@Param("idCard") String idCard);

    CompanyDisabledEmployee selectByDisabilityCertNo(@Param("disabilityCertNo") String disabilityCertNo);

    int updateById(CompanyDisabledEmployee employee);

    int deleteById(@Param("id") Long id);

    int deleteByCompanyId(@Param("companyId") Long companyId);
}
