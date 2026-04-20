package com.example.dumpdisabledsecurityfund.mapper;

import com.example.dumpdisabledsecurityfund.entity.SysUser;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface SysUserMapper {
    int insert(SysUser sysUser);

    SysUser selectById(@Param("id") Long id);

    SysUser selectByUsername(@Param("username") String username);

    List<SysUser> selectAll();

    List<SysUser> selectByUserType(@Param("userType") Integer userType);

    List<SysUser> selectByRegionId(@Param("regionId") Long regionId);

    List<SysUser> selectByStatus(@Param("status") Integer status);

    int updateById(SysUser sysUser);

    int updateLastLoginTime(@Param("id") Long id, @Param("loginTime") String loginTime, @Param("updateTime") String updateTime);

    int deleteById(@Param("id") Long id);

    /**
     * 更新密码
     * @param id 用户ID
     * @param password 新密码（已加密）
     * @param updateTime 更新时间
     * @return 影响行数
     */
    int updatePassword(@Param("id") Long id, @Param("password") String password, @Param("updateTime") String updateTime);

    /**
     * 搜索用户（支持关键词）
     * @param keyword 搜索关键词
     * @return 用户列表
     */
    List<SysUser> searchUsers(@Param("keyword") String keyword);

    /**
     * 分页查询用户
     * @param keyword 搜索关键词
     * @param offset 偏移量
     * @param limit 每页数量
     * @return 用户列表
     */
    List<SysUser> selectUsersWithPage(@Param("keyword") String keyword, @Param("offset") int offset, @Param("limit") int limit);

    /**
     * 统计用户总数
     * @param keyword 搜索关键词
     * @return 总数
     */
    long countUsers(@Param("keyword") String keyword);
}
