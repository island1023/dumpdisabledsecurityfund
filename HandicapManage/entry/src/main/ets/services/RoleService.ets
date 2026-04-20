import { get, post, put } from './HttpUtil';

/**
 * 角色信息
 */
export interface Role {
  id: string;
  roleName: string;
  roleCode: string;
  remark: string;
  status: number; // 0-禁用，1-启用
  createTime: string;
}

/**
 * 新增/修改角色请求参数
 */
export interface RoleRequest {
  roleName?: string;
  roleCode?: string;
  remark?: string;
}

/**
 * 角色服务
 */
export class RoleService {
  /**
   * 获取角色列表
   */
  static async getRoleList(): Promise<Role[]> {
    const response = await get<Role[]>('/role/list');
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 新增角色
   */
  static async addRole(role: RoleRequest): Promise<boolean> {
    const requestData: Record<string, Object> = {
      roleName: role.roleName || '',
      roleCode: role.roleCode || '',
      remark: role.remark || ''
    };

    const response = await post('/role/create', requestData);
    return response.code === 200;
  }

  /**
   * 修改角色
   */
  static async updateRole(id: string, role: RoleRequest): Promise<boolean> {
    const requestData: Record<string, Object> = {
      id: id,
      roleName: role.roleName || '',
      roleCode: role.roleCode || '',
      remark: role.remark || ''
    };

    const response = await put('/role/update', requestData);
    return response.code === 200;
  }

  /**
   * 切换角色状态
   */
  static async toggleRoleStatus(roleId: string, status: number): Promise<boolean> {
    const url = `/role/status/${roleId}`;
    const params: Record<string, string | number | boolean> = {};
    params.status = status;
    
    const response = await put(url, {}, params);
    return response.code === 200;
  }
}
