import { get, post, put } from './HttpUtil';
import { User, LoginResponse } from '../models/UserModel';

/**
 * 验证码响应
 */
export interface CaptchaResponse {
  captchaKey: string;
  captchaImage: string;
}

interface LoginRequestData {
  username: string;
  password: string;
  captchaKey: string;
  captchaCode: string;
}

/**
 * 认证服务
 */
export class AuthService {
  /**
   * 获取验证码
   */
  static async getCaptcha(): Promise<CaptchaResponse> {
    const response = await post<CaptchaResponse>('/auth/captcha', {} as Record<string, Object>);
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
    const loginData: Record<string, Object> = {};
    loginData.username = username as Object;
    loginData.password = password as Object;
    loginData.captchaKey = captchaKey as Object;
    loginData.captchaCode = captchaCode as Object;
    
    const response = await post<Record<string, Object>>('/auth/login', loginData);

    if (response.code === 200) {
      return {
        success: true,
        message: '登录成功',
        token: response.data.token as string,
        user: AuthService.convertUser(response.data.user as Record<string, Object>)
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
  static async updateProfile(profile: Record<string, Object>): Promise<boolean> {
    const response = await put('/auth/profile', profile);
    return response.code === 200;
  }

  /**
   * 转换用户数据格式
   */
  private static convertUser(userData: Record<string, Object>): User {
    return {
      id: userData.id as string,
      username: userData.username as string,
      password: '',
      realName: userData.realName as string,
      role: userData.role as string,
      phone: '',
      email: '',
      districtCode: '',
      districtName: '',
      status: (userData.status as string) === '启用' ? 'ACTIVE' : 'INACTIVE',
      createTime: userData.createTime as string,
      lastLoginTime: ''
    };
  }
}
