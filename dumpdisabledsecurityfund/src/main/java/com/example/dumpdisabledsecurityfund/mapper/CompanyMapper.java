package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.Company;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Map;
import java.util.List;

@Mapper
public interface CompanyMapper {
    int insert(Company company);

    Company selectById(@Param("id") Long id);

    Map<String, Object> selectInfoMapById(@Param("id") Long id);

    Company selectByCreditCode(@Param("creditCode") String creditCode);

    List<Company> selectAll();

    List<Company> selectByRegionId(@Param("regionId") Long regionId);

    List<Company> selectByStatus(@Param("status") Integer status);

    int updateById(Company company);

    int deleteById(@Param("id") Long id);

    /**
     * 搜索企业
     * @param keyword 搜索关键词
     * @return 企业列表
     */
    List<Company> searchCompanies(@Param("keyword") String keyword);

    /**
     * 分页查询企业
     * @param keyword 搜索关键词
     * @param offset 偏移量
     * @param limit 每页数量
     * @return 企业列表
     */
    List<Company> selectCompaniesWithPage(@Param("keyword") String keyword, @Param("offset") int offset, @Param("limit") int limit);

    /**
     * 统计企业总数
     * @param keyword 搜索关键词
     * @return 总数
     */
    long countCompanies(@Param("keyword") String keyword);

    /**
     * 领导端分页（区级按 regionId 过滤，市级 regionId 为空表示全市）
     */
    List<Company> selectCompaniesWithPageForLeader(@Param("keyword") String keyword,
                                                   @Param("regionId") Long regionId,
                                                   @Param("offset") int offset,
                                                   @Param("limit") int limit);

    long countCompaniesForLeader(@Param("keyword") String keyword, @Param("regionId") Long regionId);

    /**
     * 统计所有企业数
     * @return 总数
     */
    long countAll();
}
