import { get, post, put, del, uploadFile } from './HttpUtil';
import { User, UserListResponse, UserQueryParams } from '../models/UserModel';

class UserUpsertRequestData {
  username?: string;
  realName?: string;
  role?: string;
  district?: string;
  status?: string;
}

/**
 * 重置密码响应
 */
export interface ResetPasswordResponse {
  password?: string;
  newPassword?: string;
  data?: ResetPasswordResponse;
}

/**
 * 导入用户结果
 */
export interface ImportError {
  row: number;
  username: string;
  message: string;
}

export interface ImportResult {
  successCount: number;
  failCount: number;
  errors: ImportError[];
}

interface AddUserResponse {
  id: string;
  username: string;
  password: string;
}

/**
 * 系统用户服务
 */
export class SystemUserService {
  /**
   * 获取用户列表
   */
  static async getUserList(params: UserQueryParams): Promise<UserListResponse> {
    const queryParams: Record<string, string | number | boolean> = {};
    if (params.pageNum) {
      queryParams.pageNum = params.pageNum;
    }
    if (params.pageSize) {
      queryParams.pageSize = params.pageSize;
    }
    
    if (params.keyword) {
      queryParams.keyword = params.keyword;
    }
    
    console.log('调用用户列表接口，参数:', JSON.stringify(queryParams));
    const response = await get<Record<string, Object>>('/system/users', queryParams);
    console.log('接口返回数据:', JSON.stringify(response));
    
    if (response.code === 200) {
      const dataList = response.data.list as Array<Record<string, Object>>;
      console.log('用户原始数据列表:', JSON.stringify(dataList));
      const userList: User[] = [];
      for (let i = 0; i < dataList.length; i++) {
        userList.push(SystemUserService.convertUser(dataList[i]));
      }
      console.log('转换后的用户列表数量:', userList.length);
      return {
        total: response.data.total as number,
        list: userList
      };
    }
    
    throw new Error(response.message);
  }

  /**
   * 新增用户
   */
  static async addUser(user: Partial<User>): Promise<AddUserResponse> {
    console.log('=== SystemUserService.addUser 开始 ===');
    console.log('传入参数:', JSON.stringify(user));
    
    const requestData = new UserUpsertRequestData();
    if (user.username) {
      requestData.username = user.username;
    }
    if (user.realName) {
      requestData.realName = user.realName;
    }
    if (user.role) {
      requestData.role = user.role;
    }
    if (user.districtName) {
      requestData.district = user.districtName;
    }
    
    console.log('构建的请求数据:', JSON.stringify(requestData));
    console.log('请求URL: /system/users');
    
    try {
      const response = await post<AddUserResponse>('/system/users', requestData);
      console.log('接口响应:', JSON.stringify(response));
      
      if (response.code >= 200 && response.code < 300) {
        console.log('=== SystemUserService.addUser 成功 ===');
        return response.data;
      }
      
      console.error('接口返回错误码:', response.code, '消息:', response.message);
      throw new Error(response.message);
    } catch (error) {
      console.error('=== SystemUserService.addUser 异常 ===');
      console.error('错误详情:', error);
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(String(error));
      }
    }
  }

  /**
   * 更新用户
   */
  static async updateUser(userId: string, user: Partial<User>): Promise<boolean> {
    const requestData = new UserUpsertRequestData();
    if (user.realName) {
      requestData.realName = user.realName;
    }
    if (user.role) {
      requestData.role = user.role;
    }
    if (user.districtName) {
      requestData.district = user.districtName;
    }
    if (user.status) {
      requestData.status = user.status;
    }
    
    const response = await put(`/system/users/${userId}`, requestData);
    return response.code >= 200 && response.code < 300;
  }

  /**
   * 删除用户
   */
  static async deleteUser(userId: string): Promise<boolean> {
    const response = await del(`/system/users/${userId}`);
    return response.code === 200;
  }

  /**
   * 切换用户状态
   */
  static async toggleStatus(userId: string, status: string): Promise<boolean> {
    const url = `/system/users/${userId}`;
    const requestData = new UserUpsertRequestData();
    requestData.status = status;
    const response = await put(url, requestData);
    return response.code === 200;
  }

  /**
   * 重置密码 - 后端使用PUT
   */
  static async resetPassword(userId: string): Promise<string> {
    const url = `/system/users/${userId}/reset-password`;
    console.log('重置密码请求URL:', url);
    
    const response = await put<ResetPasswordResponse>(url);
    console.log('重置密码响应:', JSON.stringify(response));

    if (response.code === 200) {
      const data = response.data;
      // 兼容后端可能返回 data 嵌套、空字符串或不同字段的情况
      const password = data.password
        ? data.password
        : (data.newPassword
          ? data.newPassword
          : (data.data && data.data.password
            ? data.data.password
            : (data.data && data.data.newPassword ? data.data.newPassword : '')));
      if (password && password.trim().length > 0) {
        return password;
      }
      console.warn('重置成功但接口未返回有效密码字段，默认显示 123456');
      return '123456';
    }

    throw new Error(response.message);
  }

  /**
   * 通过Excel导入用户
   */
  static async importUsersByExcel(fileUri: string, fileName: string): Promise<ImportResult> {
    console.log('开始导入Excel文件:', fileName);
    const response = await uploadFile<ImportResult>('/system/users/import', fileUri, 'file', fileName);
    if (response.code === 200) {
      return response.data;
    }
    throw new Error(response.message || 'Excel导入失败');
  }

  /**
   * 转换用户数据格式
   */
  private static convertUser(userData: Record<string, Object>): User {
    // 处理status字段，后端返回的可能是字符串或数字
    let status: 'ACTIVE' | 'INACTIVE' = 'INACTIVE';
    const rawStatus = userData.status;
    if (rawStatus === '启用' || rawStatus === 'ACTIVE' || rawStatus === 1) {
      status = 'ACTIVE';
    } else if (rawStatus === '禁用' || rawStatus === 'INACTIVE' || rawStatus === 0) {
      status = 'INACTIVE';
    }
    
    return {
      id: userData.id as string,
      username: userData.username as string,
      password: '',
      realName: userData.realName as string,
      role: userData.role as string,
      phone: (userData.phone || '') as string,
      email: (userData.email || '') as string,
      districtCode: (userData.districtCode || '') as string,
      districtName: (userData.districtName || '') as string,
      status: status,
      createTime: userData.createTime as string,
      lastLoginTime: (userData.lastLoginTime || '') as string
    };
  }
}
