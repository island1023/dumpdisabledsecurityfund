package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.Region;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface RegionMapper {
    int insert(Region region);

    Region selectById(@Param("id") Long id);

    List<Region> selectAll();

    List<Region> selectByLevel(@Param("level") Integer level);

    List<Region> selectByParentId(@Param("parentId") Long parentId);

    List<Region> selectCityList();

    List<Region> selectDistrictList();

    int updateById(Region region);

    int deleteById(@Param("id") Long id);

    Region selectByName(@Param("name") String name);
}
