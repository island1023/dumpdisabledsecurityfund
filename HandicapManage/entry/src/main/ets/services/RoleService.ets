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
 * 新增/修改角色请求参数（业务层）
 */
export interface RoleRequest {
  roleName?: string;
  roleCode?: string;
  remark?: string;
}

/**
 * 新增角色请求体（ArkTS 要求显式类型）
 */
interface CreateRoleBody {
  roleName: string;
  roleCode: string;
  remark: string;
}

/**
 * 修改角色请求体
 */
interface UpdateRoleBody {
  id: string;
  roleName: string;
  roleCode: string;
  remark: string;
}

/**
 * 切换状态查询参数
 */
interface ToggleStatusParams {
  status: number;
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
    const requestData: CreateRoleBody = {
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
    const requestData: UpdateRoleBody = {
      id: id,
      roleName: role.roleName || '',
      roleCode: role.roleCode || '',
      remark: role.remark || ''
    };

    const response = await put('/role/update', requestData);
    return response.code === 200;
  }
}
  /**
   * 切换角色状态
   */
  /**
  static async toggleRoleStatus(roleId: string, status: number): Promise<boolean> {
    const url = `/role/status/${roleId}`;
    const params: ToggleStatusParams = { status };

    const response = await put(url, {}, params);
    return response.code === 200;
  }
}
  */