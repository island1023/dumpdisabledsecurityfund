package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CompanyDisabledEmployee;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CompanyDisabledEmployeeMapper {
    int insert(CompanyDisabledEmployee employee);

    CompanyDisabledEmployee selectById(@Param("id") Long id);

    List<CompanyDisabledEmployee> selectByCompanyId(@Param("companyId") Long companyId);

    List<CompanyDisabledEmployee> selectByCompanyIdAndStatus(@Param("companyId") Long companyId, @Param("isActive") Integer isActive);

    int updateById(CompanyDisabledEmployee employee);

    int deleteById(@Param("id") Long id);

    /**
     * 根据身份证号查询
     * @param idCard 身份证号
     * @return 残疾员工
     */
    CompanyDisabledEmployee selectByIdCard(@Param("idCard") String idCard);

    /**
     * 统计在职残疾员工数
     * @param companyId 公司ID
     * @return 在职残疾员工数
     */
    long countActiveByCompanyId(@Param("companyId") Long companyId);
}
