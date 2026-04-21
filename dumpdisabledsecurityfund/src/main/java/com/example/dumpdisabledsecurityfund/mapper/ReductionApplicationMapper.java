package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.ReductionApplication;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 减免缓申请Mapper
 */
@Mapper
public interface ReductionApplicationMapper {
    
    ReductionApplication selectById(Long id);
    
    List<ReductionApplication> selectByStatus(@Param("status") Integer status);
    
    List<ReductionApplication> selectByCompanyId(@Param("companyId") Long companyId);
    
    int insert(ReductionApplication record);
    
    int updateById(ReductionApplication record);
    
    int deleteById(Long id);
}
