import { http } from '@kit.NetworkKit';

/**
 * API响应结构
 */
export interface ApiResponse<T = Object> {
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
  data?: Object;
  header?: Record<string, string>;
}

export class DownloadProbeResult {
  ok: boolean = false;
  message: string = '';
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
// const BASE_URL = 'http://10.0.2.2:8080'; // 模拟器访问宿主机
const BASE_URL = 'http://10.0.2.2:8080'; // 预览器调试用

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

function shouldAttachToken(url: string): boolean {
  return !(url === '/auth/login' || url === '/auth/captcha');
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

export function buildAuthorizedGetUrl(url: string, params?: Record<string, string | number | boolean>): string {
  const mergedParams: Record<string, string | number | boolean> = {};
  if (params) {
    const entries = Object.entries(params);
    for (let i = 0; i < entries.length; i++) {
      mergedParams[entries[i][0]] = entries[i][1];
    }
  }
  const token = getToken();
  if (token && shouldAttachToken(url)) {
    mergedParams['token'] = token;
  }
  return buildUrl(url, mergedParams);
}

export function buildAuthorizedGetUrlWithQuery(urlWithQuery: string): string {
  let fullUrl = `${BASE_URL}${urlWithQuery}`;
  const token = getToken();
  if (token && shouldAttachToken(urlWithQuery)) {
    const separator = fullUrl.includes('?') ? '&' : '?';
    fullUrl += `${separator}token=${encodeURIComponent(token)}`;
  }
  return fullUrl;
}

function looksLikePdfContent(raw: string): boolean {
  if (!raw || raw.length === 0) {
    return false;
  }
  return raw.startsWith('%PDF-') || raw.includes('%PDF-');
}

function looksLikeZipContent(raw: string): boolean {
  if (!raw || raw.length === 0) {
    return false;
  }
  return raw.startsWith('PK') || raw.includes('PK');
}

function resolveProbeErrorMessage(raw: string, defaultMessage: string): string {
  if (!raw || raw.trim().length === 0) {
    return defaultMessage;
  }
  try {
    const obj = JSON.parse(raw) as Record<string, Object>;
    const messageValue = obj['message'];
    if (typeof messageValue === 'string' && messageValue.trim().length > 0) {
      return messageValue;
    }
  } catch (e) {
    // ignore parse errors, fallback to default message
  }
  return defaultMessage;
}

export async function probeDownloadUrl(urlWithQuery: string, expectZip: boolean = false): Promise<DownloadProbeResult> {
  const result = new DownloadProbeResult();
  const httpRequest = http.createHttp();
  try {
    const fullUrl = buildAuthorizedGetUrlWithQuery(urlWithQuery);
    const headers: Record<string, string> = {};
    const token = getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    const response = await httpRequest.request(fullUrl, {
      method: http.RequestMethod.GET,
      header: headers,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 15000,
      readTimeout: 15000
    });
    const body = String(response.result ?? '');
    if (response.responseCode < 200 || response.responseCode >= 300) {
      result.ok = false;
      result.message = resolveProbeErrorMessage(body, `下载失败（HTTP ${response.responseCode}）`);
      return result;
    }

    const contentValid = expectZip ? looksLikeZipContent(body) : looksLikePdfContent(body);
    if (contentValid) {
      result.ok = true;
      result.message = '';
      return result;
    }

    result.ok = false;
    result.message = resolveProbeErrorMessage(body, expectZip ? '下载内容不是有效ZIP文件' : '下载内容不是有效PDF文件');
    return result;
  } catch (error) {
    result.ok = false;
    result.message = error instanceof Error ? `下载校验失败: ${error.message}` : '下载校验失败';
    return result;
  } finally {
    httpRequest.destroy();
  }
}

/**
 * 发送HTTP请求
 */
export async function request<T = Object>(config: HttpRequestConfig): Promise<ApiResponse<T>> {
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
    
    if (token && shouldAttachToken(url)) {
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
    
    if (response.responseCode >= 200 && response.responseCode < 300) {
      const rawResult = response.result as string;
      if (!rawResult || rawResult.trim().length === 0) {
        console.warn(`HTTP成功但响应体为空，使用默认成功响应: ${response.responseCode}`);
        const fallbackJson = `{"code":${response.responseCode},"message":"","data":{}}`;
        const fallbackResult: ApiResponse<T> = JSON.parse(fallbackJson);
        console.log('=== HttpUtil.request 成功(空响应兜底) ===');
        return fallbackResult;
      }

      const result: ApiResponse<T> = JSON.parse(rawResult);
      
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
export function get(url: string, params?: Record<string, string | number | boolean>): Promise<ApiResponse<Object>>;
export function get<T>(url: string, params?: Record<string, string | number | boolean>): Promise<ApiResponse<T>>;
export function get<T = Object>(url: string, params?: Record<string, string | number | boolean>): Promise<ApiResponse<T>> {
  return request<T>({
    url,
    method: 'GET',
    params
  });
}

/**
 * POST请求
 */
export function post(url: string, data?: Object): Promise<ApiResponse<Object>>;
export function post<T>(url: string, data?: Object): Promise<ApiResponse<T>>;
export function post<T = Object>(url: string, data?: Object): Promise<ApiResponse<T>> {
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
export function put(url: string, data?: Object, params?: Record<string, string | number | boolean>): Promise<ApiResponse<Object>>;
export function put<T>(url: string, data?: Object, params?: Record<string, string | number | boolean>): Promise<ApiResponse<T>>;
export function put<T = Object>(url: string, data?: Object, params?: Record<string, string | number | boolean>): Promise<ApiResponse<T>> {
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
export function del(url: string): Promise<ApiResponse<Object>>;
export function del<T>(url: string): Promise<ApiResponse<T>>;
export function del<T = Object>(url: string): Promise<ApiResponse<T>> {
  return request<T>({
    url,
    method: 'DELETE'
  });
}

/**
 * 文件上传（multipart/form-data）
 */
export async function uploadFile<T = Object>(
  url: string,
  filePath: string,
  formFieldName: string = 'file',
  fileName: string = 'import.xlsx'
): Promise<ApiResponse<T>> {
  const httpRequest = http.createHttp();

  try {
    const token = getToken();
    const headers: Record<string, string> = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const fullUrl = buildUrl(url);
    
    const requestOptions: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: headers,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 30000,
      readTimeout: 30000,
      multiFormDataList: [
        {
          name: formFieldName,
          contentType: 'application/octet-stream',
          remoteFileName: fileName,
          filePath: filePath
        }
      ]
    };

    const response = await httpRequest.request(fullUrl, requestOptions);
    if (response.responseCode === 200) {
      return JSON.parse(response.result as string) as ApiResponse<T>;
    }
    throw new Error(`HTTP错误: ${response.responseCode}`);
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    throw new Error(`文件上传失败: ${errorMessage}`);
  } finally {
    httpRequest.destroy();
  }
}
