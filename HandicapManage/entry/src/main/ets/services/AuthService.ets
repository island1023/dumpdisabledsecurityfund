import { get, post, put } from './HttpUtil';
import { User, LoginResponse } from '../models/UserModel';

/**
 * 验证码响应
 */
export interface CaptchaResponse {
  captchaKey: string;
  captchaImage: string;
}

class LoginRequestData {
  username: string = '';
  password: string = '';
  captchaKey: string = '';
  captchaCode: string = '';
  accountType: string = '';
}

class ChangePasswordRequestData {
  oldPassword: string = '';
  newPassword: string = '';
  confirmPassword: string = '';
}

/**
 * 认证服务
 */
export class AuthService {
  private static mapBackendRole(rawRole: string): string {
    const role = rawRole.trim().toLowerCase();
    const roleMap: Record<string, string> = {
      'system_admin': 'SYSTEM_ADMIN',
      'admin_system': 'SYSTEM_ADMIN',
      'district_admin': 'DISTRICT_ADMIN',
      'admin_district': 'DISTRICT_ADMIN',
      'city_admin': 'CITY_ADMIN',
      'admin_city': 'CITY_ADMIN',
      'district_leader': 'DISTRICT_LEADER',
      'leader_district': 'DISTRICT_LEADER',
      'city_leader': 'CITY_LEADER',
      'leader_city': 'CITY_LEADER',
      'unit': 'UNIT',
      'company': 'UNIT',
      'company_user': 'UNIT'
    };
    if (roleMap[role]) {
      return roleMap[role];
    }
    const upperRole = rawRole.trim().toUpperCase();
    return upperRole ? upperRole : 'UNIT';
  }

  private static resolveUserRole(userData: Record<string, Object>, accountTypeHint?: string): string {
    if (accountTypeHint) {
      const hint = accountTypeHint.trim().toLowerCase();
      if (hint === 'company') {
        return 'UNIT';
      }
    }
    if (userData.role && String(userData.role).trim().length > 0) {
      return AuthService.mapBackendRole(String(userData.role));
    }
    if (userData.roleCode && String(userData.roleCode).trim().length > 0) {
      return AuthService.mapBackendRole(String(userData.roleCode));
    }
    if (userData.accountType && String(userData.accountType).trim().length > 0) {
      return AuthService.mapBackendRole(String(userData.accountType));
    }
    return 'UNIT';
  }

  /**
   * 获取验证码
   */
  static async getCaptcha(): Promise<CaptchaResponse> {
    const response = await post<CaptchaResponse>('/auth/captcha', new Object());
    console.log('Captcha API response code:', response.code);
    console.log('Captcha API response message:', response.message);
    console.log('Captcha API response data:', JSON.stringify(response.data));
    
    if (response.code === 200) {
      return response.data;
    }
    throw new Error(response.message || '获取验证码失败');
  }

  /**
   * 用户登录
   */
  static async login(username: string, password: string, captchaKey: string, captchaCode: string): Promise<LoginResponse> {
    const loginData = new LoginRequestData();
    loginData.username = username;
    loginData.password = password;
    loginData.captchaKey = captchaKey;
    loginData.captchaCode = captchaCode;
    // 单位账号走 company 体系，避免拿到 sys 角色令牌
    loginData.accountType = username.trim().toLowerCase().startsWith('unit') ? 'company' : 'sys';
    
    const response = await post<Record<string, Object>>('/auth/login', loginData);

    if (response.code === 200) {
      const responseData = response.data as Record<string, Object>;
      const userPayload = responseData.user
        ? responseData.user as Record<string, Object>
        : responseData;
      const accountType = responseData.accountType
        ? String(responseData.accountType)
        : loginData.accountType;
      return {
        success: true,
        message: '登录成功',
        token: responseData.token as string,
        user: AuthService.convertUser(userPayload, accountType)
      };
    }

    return {
      success: false,
      message: response.message
    };
  }

  /**
   * 修改个人信息
   */
  static async updateProfile(profile: Object): Promise<boolean> {
    const response = await put('/auth/profile', profile);
    return response.code === 200;
  }

  /**
   * 修改密码
   */
  static async changePassword(userId: string, accountType: string, oldPassword: string, newPassword: string, confirmPassword: string): Promise<boolean> {
    const requestData = new ChangePasswordRequestData();
    requestData.oldPassword = oldPassword;
    requestData.newPassword = newPassword;
    requestData.confirmPassword = confirmPassword;

    const url = `/auth/change-password?userId=${encodeURIComponent(userId)}&accountType=${encodeURIComponent(accountType)}`;
    const response = await put(url, requestData);
    if (response.code === 200) {
      return true;
    }
    throw new Error(response.message || '修改密码失败');
  }

  /**
   * 转换用户数据格式
   */
  private static convertUser(userData: Record<string, Object>, accountTypeHint: string = ''): User {
    const resolvedRole = AuthService.resolveUserRole(userData, accountTypeHint);
    return {
      id: userData.id as string,
      username: userData.username as string,
      password: '',
      realName: userData.realName as string,
      role: resolvedRole,
      phone: '',
      email: '',
      districtCode: (userData.districtCode || '') as string,
      districtName: (userData.districtName || '') as string,
      status: (userData.status as string) === '启用' ? 'ACTIVE' : 'INACTIVE',
      createTime: userData.createTime as string,
      lastLoginTime: ''
    };
  }
}
