package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.CalculationRule;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CalculationRuleMapper {
    int insert(CalculationRule rule);

    int updateById(CalculationRule rule);

    int deleteById(@Param("id") Long id);

    CalculationRule selectById(@Param("id") Long id);

    List<CalculationRule> selectAll();

    CalculationRule selectActiveByYear(@Param("year") Integer year);

    Double selectActiveRatioByYear(@Param("year") Integer year);

    int deactivateByYear(@Param("year") Integer year);

    List<CalculationRule> selectByYearRange(@Param("startYear") Integer startYear, @Param("endYear") Integer endYear);
}
