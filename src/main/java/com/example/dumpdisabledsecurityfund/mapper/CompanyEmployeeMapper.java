package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CompanyEmployee;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CompanyEmployeeMapper {
    int insert(CompanyEmployee employee);

    CompanyEmployee selectById(@Param("id") Long id);

    List<CompanyEmployee> selectByCompanyId(@Param("companyId") Long companyId);

    List<CompanyEmployee> selectByCompanyIdAndStatus(@Param("companyId") Long companyId, @Param("isActive") Integer isActive);

    int updateById(CompanyEmployee employee);

    int deleteById(@Param("id") Long id);

    /**
     * 分页查询员工
     * @param companyId 公司ID
     * @param offset 偏移量
     * @param limit 每页数量
     * @return 员工列表
     */
    List<CompanyEmployee> selectEmployeesWithPage(@Param("companyId") Long companyId, @Param("offset") int offset, @Param("limit") int limit);

    /**
     * 统计员工总数
     * @param companyId 公司ID
     * @return 总数
     */
    long countEmployees(@Param("companyId") Long companyId);

    /**
     * 统计在职员工数
     * @param companyId 公司ID
     * @return 在职员工数
     */
    long countActiveByCompanyId(@Param("companyId") Long companyId);
}
