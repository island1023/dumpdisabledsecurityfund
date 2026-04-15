package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.EmployeeRegistration;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface EmployeeRegistrationMapper {
    int insert(EmployeeRegistration registration);

    EmployeeRegistration selectById(@Param("id") Long id);

    List<EmployeeRegistration> selectByCompanyId(@Param("companyId") Long companyId);

    List<EmployeeRegistration> selectByCompanyIdAndYear(@Param("companyId") Long companyId, @Param("year") Integer year);

    List<EmployeeRegistration> selectByStatus(@Param("status") Integer status);

    EmployeeRegistration selectByIdCard(@Param("idCard") String idCard);

    int updateById(EmployeeRegistration registration);

    int updateStatus(@Param("id") Long id, @Param("status") Integer status, @Param("updateTime") String updateTime);

    int deleteById(@Param("id") Long id);

    int deleteByCompanyIdAndYear(@Param("companyId") Long companyId, @Param("year") Integer year);
}
