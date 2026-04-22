import { http } from '@kit.NetworkKit';
import { request as requestSdk } from '@kit.BasicServicesKit'; // 重命名以避免冲突
import { common } from '@kit.AbilityKit';

/**
 * API响应结构
 */
export interface ApiResponse<T = Object> {
  code: number;
  message: string;
  data: T; // 将 data 设置为可选
}

interface UploadFileConfig {
  filename: string;
  name: string;
  uri: string;
  type: string;
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
//const BASE_URL = 'http://localhost:8080'; // 预览器调试用

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

/**
 * 发送HTTP请求
 */
export async function request<T = Object>(config: HttpRequestConfig): Promise<ApiResponse<T>> {
  const url = config.url;
  const method = config.method;
  const params = config.params;
  const data = config.data;

  // 核心修正：统一使用 headers 这个变量名
  const headers: Record<string, string> = {};
  headers['Content-Type'] = 'application/json';

  console.log('=== HttpUtil.request 开始 ===');
  const httpRequest = http.createHttp();

  try {
    const token = getToken();

    // 合并 config 传入的自定义 header
    if (config.header) {
      const headerKeys = Object.keys(config.header);
      for (let i = 0; i < headerKeys.length; i++) {
        const key = headerKeys[i];
        // 修正：这里必须使用 config.header 而不是不存在的全局变量 header
        headers[key] = config.header[key];
      }
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
  // 修正：显式声明 config 类型，解决 arkts-no-untyped-obj-literals
  const config: HttpRequestConfig = {
    url: url,
    method: 'DELETE'
  };
  return request<T>(config);
}


export async function uploadFile<T = Object>(
  urlPath: string,
  filePath: string,
  formFieldName: string = 'file',
  fileName: string = 'import.xlsx',
  mimeType?: string
): Promise<ApiResponse<T>> {
  console.info('[HttpUtil] 🔴🔴🔴 开始文件上传 🔴🔴🔴');
  console.info('[HttpUtil] 接口路径:', urlPath);
  console.info('[HttpUtil] 原始文件路径:', filePath);

  const token = getToken();
  const fullUrl = buildUrl(urlPath);
  const context = getContext() as common.UIAbilityContext;

  console.info('[HttpUtil] 完整URL:', fullUrl);

  const lastSlashIndex = filePath.lastIndexOf('/');
  const realFileName = lastSlashIndex !== -1 ? filePath.substring(lastSlashIndex + 1) : fileName;

  console.info('[HttpUtil] 真实文件名:', realFileName);

  if (!mimeType) {
    const lowerName = realFileName.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (lowerName.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (lowerName.endsWith('.gif')) {
      mimeType = 'image/gif';
    } else if (lowerName.endsWith('.xlsx')) {
      mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else if (lowerName.endsWith('.xls')) {
      mimeType = 'application/vnd.ms-excel';
    } else {
      mimeType = 'application/octet-stream';
    }
  }

  console.info('[HttpUtil] MIME类型:', mimeType);

  const internalUri = `internal://cache/${realFileName}`;
  console.info('[HttpUtil] 转换后的内部URI:', internalUri);

  const fileItem: requestSdk.File = {
    filename: realFileName,
    name: formFieldName,
    uri: internalUri,
    type: mimeType
  };

  const uploadHeader: Record<string, string> = {};
  if (token) {
    uploadHeader['Authorization'] = `Bearer ${token}`;
    console.info('[HttpUtil] 已添加Token认证');
  }

  const uploadConfig: requestSdk.UploadConfig = {
    url: fullUrl,
    method: 'POST',
    header: uploadHeader,
    files: [fileItem],
    data: []
  };

  try {
    console.info('[HttpUtil] 创建上传任务...');
    const uploadTask: requestSdk.UploadTask = await requestSdk.uploadFile(context, uploadConfig);
    console.info('[HttpUtil] 上传任务创建成功');

    return new Promise((resolve, reject) => {
      uploadTask.on('progress', (receivedSize: number, totalSize: number) => {
        const progress = totalSize > 0 ? Math.round((receivedSize / totalSize) * 100) : 0;
        console.info(`[HttpUtil] 上传进度: ${progress}% (${receivedSize}/${totalSize})`);
      });

      uploadTask.on('fail', (err: Array<requestSdk.TaskState>) => {
        console.error('[HttpUtil] ❌ 上传任务失败详情:', JSON.stringify(err));
        if (err && err.length > 0) {
          const errorState = err[0];
          console.error('[HttpUtil] 错误码:', errorState.responseCode);
          console.error('[HttpUtil] 错误消息:', errorState.message);
          reject(new Error(`上传失败: ${errorState.message || '未知错误'}`));
        } else {
          reject(new Error('上传服务响应失败'));
        }
      });

      uploadTask.on('complete', (states: Array<requestSdk.TaskState>) => {
        console.info('[HttpUtil] ✅ 上传任务已完成');

        if (states && states.length > 0) {
          const state = states[0];
          console.info('[HttpUtil] 响应码:', state.responseCode);
          console.info('[HttpUtil] 响应消息长度:', state.message ? state.message.length : 0);

          if (state.message) {
            console.info('[HttpUtil] 响应消息预览:', state.message.substring(0, 200));
          }

          if (state.responseCode === 200 && state.message) {
            try {
              const responseData: ApiResponse<T> = JSON.parse(state.message) as ApiResponse<T>;
              console.info('[HttpUtil] ✅ 后端返回数据:', JSON.stringify(responseData));

              if (responseData.code === 200) {
                console.info('[HttpUtil] ✅ 导入成功');
                resolve(responseData);
              } else {
                console.error('[HttpUtil] ❌ 业务逻辑失败:', responseData.message);
                reject(new Error(responseData.message || '导入业务失败'));
              }
            } catch (parseError) {
              console.warn('[HttpUtil] ⚠️ 解析后端响应失败:', parseError);
              console.warn('[HttpUtil] 原始响应:', state.message);

              const successRes: ApiResponse<T> = {
                code: 200,
                message: '文件上传成功',
                data: Object() as T
              };
              resolve(successRes);
            }
          } else if (state.responseCode && state.responseCode !== 200) {
            console.error('[HttpUtil] ❌ HTTP错误，响应码:', state.responseCode);
            reject(new Error(`上传失败，响应码: ${state.responseCode}`));
          } else {
            console.warn('[HttpUtil] ⚠️ 响应码异常，使用默认成功');
            const successRes: ApiResponse<T> = {
              code: 200,
              message: '文件上传成功',
              data: Object() as T
            };
            resolve(successRes);
          }
        } else {
          console.error('[HttpUtil] ❌ 上传任务状态异常');
          reject(new Error('上传任务状态异常'));
        }
      });

      console.info('[HttpUtil] 开始执行上传...');
    });

  } catch (error) {
    const err: Error = error instanceof Error ? error : new Error(String(error));
    console.error('[HttpUtil] ❌❌❌ 创建上传任务崩溃 ❌❌❌');
    console.error('[HttpUtil] 错误类型:', err.constructor.name);
    console.error('[HttpUtil] 错误消息:', err.message);
    console.error('[HttpUtil] 错误堆栈:', err.stack);
    throw err;
  }
}










/**
 * 文件上传（使用系统级 request 任务接口）
 * 彻底解决物理路径校验失败 (filePath is not valid) 和 Multipart 格式不标准的问题
 */
//可以正确上传，备用原始正确代码
/**export async function uploadFile<T = Object>(
  urlPath: string,
  filePath: string,
  formFieldName: string = 'file',
  fileName: string = 'import.xlsx'
): Promise<ApiResponse<T>> {
  console.error('🔴🔴🔴 使用 requestSdk.uploadFile 接口 🔴🔴🔴');

  const token = getToken(); //
  const fullUrl = buildUrl(urlPath); //
  const context = getContext() as common.UIAbilityContext;

  // 1. 从绝对路径中提取真实的文件名
  // 例如：/data/.../cache/1776772860911_import.xlsx -> 1776772860911_import.xlsx
  const lastSlashIndex = filePath.lastIndexOf('/');
  const realFileName = lastSlashIndex !== -1 ? filePath.substring(lastSlashIndex + 1) : fileName;

  // 2. 构造符合系统要求的 internal 协议路径
  // 必须使用 internal://cache/ 或 internal://files/ 协议，系统才能正确找到文件并上传
  const internalUri = `internal://cache/${realFileName}`;
  console.log('转换后的系统协议路径:', internalUri);

  // 3. 严格构造文件列表数据，符合 ArkTS 显式接口要求
  const fileItem: requestSdk.File = {
    filename: realFileName,
    name: formFieldName, // 对应后端的 @RequestParam("file")
    uri: internalUri,
    type: 'xlsx'
  };

  // 4. 显式声明 Header，避免字面量类型报错
  const uploadHeader: Record<string, string> = {};
  if (token) {
    uploadHeader['Authorization'] = `Bearer ${token}`;
  }

  // 5. 构造上传配置
  const uploadConfig: requestSdk.UploadConfig = {
    url: fullUrl,
    method: 'POST',
    header: uploadHeader,
    files: [fileItem],
    data: []
  };

  try {
    // 6. 发起系统级上传任务
    const uploadTask: requestSdk.UploadTask = await requestSdk.uploadFile(context, uploadConfig);

    return new Promise((resolve, reject) => {
      // 监听上传失败
      uploadTask.on('fail', (err: Array<requestSdk.TaskState>) => {
        console.error('上传任务失败详情:', JSON.stringify(err));
        reject(new Error('上传服务响应失败'));
      });

      // 监听上传完成
      uploadTask.on('complete', (states: Array<requestSdk.TaskState>) => {
        console.log('上传任务已完成:', JSON.stringify(states));

        // 构造符合 ApiResponse 接口的成功返回
        const successRes: ApiResponse<T> = {
          code: 200,
          message: '文件上传任务已提交',
          data: Object() as T // 使用 Object 实例化解决 {} as T 的静态检查报错
        };
        resolve(successRes);
      });
    });

  } catch (error) {
    const err: Error = error instanceof Error ? error : new Error(String(error));
    console.error('创建上传任务崩溃:', err.message);
    throw err;
  }

}
 */