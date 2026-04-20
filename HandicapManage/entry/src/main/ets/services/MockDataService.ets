import { User, LoginResponse, UserListResponse, UserQueryParams } from '../models/UserModel';

/**
 * 模拟用户服务
 */
export class MockUserService {
 // 模拟用户数据
 private static mockUsers: User[] = [
 {
 id: '1',
 username: 'admin',
 password: '123456',
 realName: '系统管理员',
 role: 'SYSTEM_ADMIN',
 phone: '13800138001',
 email: 'admin@example.com',
 districtCode: '',
 districtName: '全市',
 status: 'ACTIVE',
 createTime: '2024-01-0100:00:00',
 lastLoginTime: '2025-04-1510:30:00'
 },
 {
 id: '2',
 username: 'city_admin',
 password: '123456',
 realName: '市级管理员',
 role: 'CITY_ADMIN',
 phone: '13800138002',
 email: 'city_admin@example.com',
 districtCode: '440100',
 districtName: '广州市',
 status: 'ACTIVE',
 createTime: '2024-01-0100:00:00',
 lastLoginTime: '2025-04-1414:20:00'
 },
 {
 id: '3',
 username: 'district_admin',
 password: '123456',
 realName: '天河区管理员',
 role: 'DISTRICT_ADMIN',
 phone: '13800138003',
 email: 'district_admin@example.com',
 districtCode: '440106',
 districtName: '天河区',
 status: 'ACTIVE',
 createTime: '2024-01-0100:00:00',
 lastLoginTime: '2025-04-1509:00:00'
 },
 {
 id: '4',
 username: 'city_leader',
 password: '123456',
 realName: '市级领导',
 role: 'CITY_LEADER',
 phone: '13800138004',
 email: 'city_leader@example.com',
 districtCode: '440100',
 districtName: '广州市',
 status: 'ACTIVE',
 createTime: '2024-01-0100:00:00',
 lastLoginTime: '2025-04-1316:00:00'
 },
 {
 id: '5',
 username: 'district_leader',
 password: '123456',
 realName: '天河区领导',
 role: 'DISTRICT_LEADER',
 phone: '13800138005',
 email: 'district_leader@example.com',
 districtCode: '440106',
 districtName: '天河区',
 status: 'ACTIVE',
 createTime: '2024-01-0100:00:00',
 lastLoginTime: '2025-04-1211:00:00'
 },
 {
 id: '6',
 username: 'unit001',
 password: '123456',
 realName: '单位负责人',
 role: 'UNIT',
 phone: '13800138006',
 email: 'unit001@example.com',
 districtCode: '440106',
 districtName: '天河区',
 status: 'ACTIVE',
 createTime: '2024-01-0100:00:00',
 lastLoginTime: '2025-04-1508:30:00'
 }
 ];

 /**
 * 模拟登录
 */
 static async login(username: string, password: string): Promise<LoginResponse> {
 // 模拟网络延迟
 await MockUserService.delay(500);

 const user: User | undefined = MockUserService.mockUsers.find((u: User) => u.username === username && u.password === password);
 if (user) {
 return {
 success: true,
 message: '登录成功',
 user: user,
 token: 'mock_token_' + Date.now()
 };
 }
 return {
 success: false,
 message: '用户名或密码错误'
 };
 }

 /**
 * 获取用户列表
 */
 static async getUserList(params: UserQueryParams): Promise<UserListResponse> {
 await MockUserService.delay(300);

 let filteredList: User[] = MockUserService.mockUsers.slice();

 // 关键字过滤
 if (params.keyword) {
 const keyword: string = params.keyword.toLowerCase();
 filteredList = filteredList.filter((u: User): boolean =>
 u.username.toLowerCase().includes(keyword) ||
 u.realName.toLowerCase().includes(keyword)
 );
 }

 // 角色过滤
 if (params.role) {
 filteredList = filteredList.filter((u: User): boolean => u.role === params.role);
 }

 // 状态过滤
 if (params.status) {
 filteredList = filteredList.filter((u: User): boolean => u.status === params.status);
 }

 // 行政区划过滤
 if (params.districtCode) {
 filteredList = filteredList.filter((u: User): boolean => u.districtCode === params.districtCode);
 }

 const total = filteredList.length;
 const start = (params.pageNum -1) * params.pageSize;
 const list = filteredList.slice(start, start + params.pageSize);

 return { total, list };
 }

 /**
 * 添加用户
 */
 static async addUser(user: Partial<User>): Promise<boolean> {
 await MockUserService.delay(300);
 const newUser: User = {
 id: String(MockUserService.mockUsers.length +1),
 username: user.username || '',
 password: user.password || '123456',
 realName: user.realName || '',
 role: user.role || 'UNIT',
 phone: user.phone || '',
 email: user.email || '',
 districtCode: user.districtCode || '',
 districtName: user.districtName || '',
 status: 'ACTIVE',
 createTime: new Date().toISOString(),
 lastLoginTime: ''
 };
 MockUserService.mockUsers.push(newUser);
 return true;
 }

 /**
 * 更新用户
 */
 static async updateUser(user: Partial<User>): Promise<boolean> {
 await MockUserService.delay(300);
 const index: number = MockUserService.mockUsers.findIndex((u: User): boolean => u.id === user.id);
 if (index >=0) {
 const existingUser: User = MockUserService.mockUsers[index];
 existingUser.username = user.username || existingUser.username;
 existingUser.password = user.password || existingUser.password;
 existingUser.realName = user.realName || existingUser.realName;
 existingUser.role = user.role || existingUser.role;
 existingUser.phone = user.phone || existingUser.phone;
 existingUser.email = user.email || existingUser.email;
 existingUser.districtCode = user.districtCode || existingUser.districtCode;
 existingUser.districtName = user.districtName || existingUser.districtName;
 existingUser.status = user.status || existingUser.status;
 return true;
 }
 return false;
 }

 /**
 * 删除用户
 */
 static async deleteUser(id: string): Promise<boolean> {
 await MockUserService.delay(300);
 const index: number = MockUserService.mockUsers.findIndex((u: User): boolean => u.id === id);
 if (index >=0) {
 MockUserService.mockUsers.splice(index,1);
 return true;
 }
 return false;
 }

 /**
 * 重置密码
 */
 static async resetPassword(id: string): Promise<string> {
 await MockUserService.delay(300);
 const user: User | undefined = MockUserService.mockUsers.find((u: User): boolean => u.id === id);
 if (user) {
 user.password = '123456';
 return '123456';
 }
 return '';
 }

 /**
 * 模拟延迟
 */
 private static delay(ms: number): Promise<void> {
 return new Promise(resolve => setTimeout(resolve, ms));
 }
}
