package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface PayableAmountMapper {
    int insert(PayableAmount amount);

    PayableAmount selectByCompanyAndYear(@Param("companyId") Long companyId, @Param("year") Integer year);

    int updateById(PayableAmount amount);

    Double sumCalculatedAmountByYear(@Param("year") Integer year);

    int countByStatusAndYear(@Param("year") Integer year, @Param("status") Integer status);

    PayableAmount selectById(@Param("id") Long id);

    List<PayableAmount> selectByCompanyId(@Param("companyId") Long companyId);

    List<PayableAmount> selectByYear(@Param("year") Integer year);

    List<PayableAmount> selectAll();

    int countByYear(@Param("year") Integer year);
}
