/**
 * 用户数据模型
 */
export interface User {
 id: string;
 username: string;
 password: string;
 realName: string;
 role: string;
 phone: string;
 email: string;
 districtCode: string; // 行政区划代码
 districtName: string; // 行政区划名称
 status: 'ACTIVE' | 'INACTIVE';
 createTime: string;
 lastLoginTime: string;
}

/**
 * 用户登录响应
 */
export interface LoginResponse {
 success: boolean;
 message: string;
 user?: User;
 token?: string;
}

/**
 * 用户查询参数
 */
export interface UserQueryParams {
 keyword?: string;
 role?: string;
 status?: string;
 districtCode?: string;
 pageNum: number;
 pageSize: number;
}

/**
 * 用户列表响应
 */
export interface UserListResponse {
 total: number;
 list: User[];
}
