package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.Company;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface CompanyMapper {
    int insert(Company company);

    Company selectById(@Param("id") Long id);

    Company selectByCreditCode(@Param("creditCode") String creditCode);

    List<Company> selectAll();

    List<Company> selectByRegionId(@Param("regionId") Long regionId);

    List<Company> selectByStatus(@Param("status") Integer status);

    int countAll();

    int countByRegionId(@Param("regionId") Long regionId);

    int updateById(Company company);

    int deleteById(@Param("id") Long id);
}
