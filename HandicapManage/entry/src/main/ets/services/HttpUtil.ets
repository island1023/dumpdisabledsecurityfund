import { http } from '@kit.NetworkKit';

/**
 * API响应结构
 */
export interface ApiResponse<T = Record<string, Object>> {
  code: number;
  message: string;
  data: T;
}

/**
 * HTTP请求配置
 */
interface HttpRequestConfig {
  url: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  params?: Record<string, string | number | boolean>;
  data?: Record<string, Object>;
  header?: Record<string, string>;
}

/**
 * API基础配置 - 根据实际情况修改
 * 10.0.2.2 用于鸿蒙模拟器访问宿主机
 * localhost 用于预览器调试
 * 真机需要使用电脑的局域网IP（如 192.168.1.100）
 * 
 * 当前配置：
 * - 如果使用预览器：使用 localhost
 * - 如果使用模拟器：使用 10.0.2.2
 * - 如果使用真机：使用电脑的局域网IP
 */
const BASE_URL = 'http://10.0.2.2:8080'; // 模拟器访问宿主机
// const BASE_URL = 'http://localhost:8080'; // 预览器调试用

/**
 * 获取Token
 */
function getToken(): string {
  try {
    const token = AppStorage.get('token') as string;
    return token || '';
  } catch (e) {
    return '';
  }
}

/**
 * 构建完整URL
 */
function buildUrl(url: string, params?: Record<string, string | number | boolean>): string {
  let fullUrl = `${BASE_URL}${url}`;
  
  if (params && Object.keys(params).length > 0) {
    const entries = Object.entries(params);
    const filteredEntries: Array<[string, string | number | boolean]> = [];
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const key = entry[0];
      const value = entry[1];
      if (value !== undefined && value !== null) {
        filteredEntries.push([key, value]);
      }
    }
    
    const queryString = filteredEntries
      .map((item: [string, string | number | boolean]) => `${encodeURIComponent(item[0])}=${encodeURIComponent(String(item[1]))}`)
      .join('&');
    
    if (queryString) {
      fullUrl += `?${queryString}`;
    }
  }
  
  return fullUrl;
}

/**
 * 发送HTTP请求
 */
export async function request<T = Record<string, Object>>(config: HttpRequestConfig): Promise<ApiResponse<T>> {
  const url = config.url;
  const method = config.method;
  const params = config.params;
  const data = config.data;
  const header = config.header ? config.header : {} as Record<string, string>;
  
  console.log('=== HttpUtil.request 开始 ===');
  console.log('URL:', url);
  console.log('Method:', method);
  console.log('Params:', JSON.stringify(params));
  console.log('Data:', JSON.stringify(data));
  
  const httpRequest = http.createHttp();
  
  try {
    const token = getToken();
    console.log('Token:', token ? token.substring(0, 20) + '...' : '无');
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };
    
    // 合并header
    const headerKeys = Object.keys(header);
    for (let i = 0; i < headerKeys.length; i++) {
      const key = headerKeys[i];
      headers[key] = header[key];
    }
    
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    
    const fullUrl = buildUrl(url, params);
    console.log('完整URL:', fullUrl);
    console.log('请求头:', JSON.stringify(headers));
    console.log('开始发送HTTP请求...');
    
    const response = await httpRequest.request(
      fullUrl,
      {
        method: method as http.RequestMethod,
        header: headers,
        extraData: data ? JSON.stringify(data) : undefined,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: 30000
      }
    );
    
    console.log('HTTP响应码:', response.responseCode);
    console.log('HTTP响应内容:', response.result);
    
    if (response.responseCode === 200) {
      const result: ApiResponse<T> = JSON.parse(response.result as string);
      
      if (result.code === 401) {
        console.error('Token过期，请重新登录');
      }
      
      console.log('=== HttpUtil.request 成功 ===');
      return result;
    } else {
      throw new Error(`HTTP错误: ${response.responseCode}`);
    }
  } catch (error) {
    console.error('=== HttpUtil.request 异常 ===');
    console.error('请求失败:', error);
    if (error instanceof Error) {
      throw error;
    } else {
      throw new Error(String(error));
    }
  } finally {
    httpRequest.destroy();
  }
}

/**
 * GET请求
 */
export function get<T = Record<string, Object>>(url: string, params?: Record<string, string | number | boolean>): Promise<ApiResponse<T>> {
  return request<T>({
    url,
    method: 'GET',
    params
  });
}

/**
 * POST请求
 */
export function post<T = Record<string, Object>>(url: string, data?: Record<string, Object>): Promise<ApiResponse<T>> {
  console.log('POST request to:', url, 'with data:', JSON.stringify(data));
  return request<T>({
    url,
    method: 'POST',
    data
  });
}

/**
 * PUT请求
 */
export function put<T = Record<string, Object>>(url: string, data?: Record<string, Object>, params?: Record<string, string | number | boolean>): Promise<ApiResponse<T>> {
  return request<T>({
    url,
    method: 'PUT',
    data,
    params
  });
}

/**
 * DELETE请求
 */
export function del<T = Record<string, Object>>(url: string): Promise<ApiResponse<T>> {
  return request<T>({
    url,
    method: 'DELETE'
  });
}
