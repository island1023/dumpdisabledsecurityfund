package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.DisabledEmployee;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 残疾职工Mapper
 */
@Mapper
public interface DisabledEmployeeMapper {
    
    DisabledEmployee selectById(Long id);
    
    List<DisabledEmployee> selectByStatus(@Param("status") Integer status);
    
    List<DisabledEmployee> selectByCompanyId(@Param("companyId") Long companyId);
    
    int insert(DisabledEmployee record);
    
    int updateById(DisabledEmployee record);
    
    int deleteById(Long id);
}
