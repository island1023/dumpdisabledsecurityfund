package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CompanyDisabledEmployee;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface CompanyDisabledEmployeeMapper {

    int insert(CompanyDisabledEmployee employee);

    CompanyDisabledEmployee selectById(Long id);

    List<CompanyDisabledEmployee> selectByCompanyId(Long companyId);

    List<CompanyDisabledEmployee> selectByCompanyIdAndStatus(@Param("companyId") Long companyId,
                                                             @Param("isActive") Integer isActive);

    @Select("SELECT * FROM company_disabled_employee WHERE company_id = #{companyId} AND id_card = #{idCard}")
    CompanyDisabledEmployee selectByCompanyIdAndIdCard(@Param("companyId") Long companyId,
                                                       @Param("idCard") String idCard);

    CompanyDisabledEmployee selectByIdCard(String idCard);

    long countActiveByCompanyId(Long companyId);

    int updateById(CompanyDisabledEmployee employee);

    int deleteById(Long id);
}

