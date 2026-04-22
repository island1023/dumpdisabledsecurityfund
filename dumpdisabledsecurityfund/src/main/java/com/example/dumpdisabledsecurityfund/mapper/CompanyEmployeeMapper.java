package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CompanyEmployee;
import org.apache.ibatis.annotations.*;

import java.util.List;

@Mapper
public interface CompanyEmployeeMapper {

    int insert(CompanyEmployee employee);

    CompanyEmployee selectById(Long id);

    List<CompanyEmployee> selectByCompanyId(Long companyId);

    @Select("SELECT * FROM company_employee WHERE company_id = #{companyId} AND id_card = #{idCard}")
    CompanyEmployee selectByCompanyIdAndIdCard(@Param("companyId") Long companyId,
                                               @Param("idCard") String idCard);

    List<CompanyEmployee> selectEmployeesWithPage(@Param("companyId") Long companyId,
                                                  @Param("offset") int offset,
                                                  @Param("pageSize") int pageSize);

    long countEmployees(Long companyId);

    long countActiveByCompanyId(Long companyId);

    int updateById(CompanyEmployee employee);

    int deleteById(Long id);
}
