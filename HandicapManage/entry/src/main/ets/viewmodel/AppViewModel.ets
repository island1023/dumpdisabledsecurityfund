import { User } from '../models/UserModel';

/**
 * 应用全局状态管理
 */
@Observed
export class AppViewModel {
 private static instance: AppViewModel;

 // 当前登录用户
 currentUser: User | null = null;

 // 登录token
 token: string = '';

 // 是否已登录
 isLoggedIn: boolean = false;

 // 当前页面路径
 currentPage: string = 'home';

 // 当前选中的菜单
 currentMenu: string = 'home';

 // 私有构造函数
 private constructor() {}

 /**
 * 获取单例实例
 */
 static getInstance(): AppViewModel {
 if (!AppViewModel.instance) {
 AppViewModel.instance = new AppViewModel();
 }
 return AppViewModel.instance;
 }

 /**
 * 设置当前用户
 */
 setUser(user: User | null): void {
 this.currentUser = user;
 this.isLoggedIn = user !== null;
 }

 /**
 * 设置token
 */
 setToken(token: string): void {
 this.token = token;
 }

 /**
 * 登出
 */
 logout(): void {
 this.currentUser = null;
 this.token = '';
 this.isLoggedIn = false;
 this.currentPage = 'home';
 this.currentMenu = 'home';
 }

 /**
 * 切换菜单
 */
 switchMenu(menuId: string): void {
 this.currentMenu = menuId;
 this.currentPage = menuId;
 }

 /**
 * 检查是否有权限访问某个菜单
 */
 hasPermission(menuId: string): boolean {
 if (!this.currentUser) {
 return false;
 }
 // 系统管理员拥有所有权限
 if (this.currentUser.role === 'SYSTEM_ADMIN') {
 return true;
 }
 // 其他角色根据菜单配置判断
 const menuPermissions: Record<string, string[]> = {
 'home': ['SYSTEM_ADMIN', 'DISTRICT_ADMIN', 'CITY_ADMIN', 'DISTRICT_LEADER', 'CITY_LEADER', 'UNIT'],
 'system': ['SYSTEM_ADMIN'],
 'unit': ['SYSTEM_ADMIN', 'DISTRICT_ADMIN', 'CITY_ADMIN', 'DISTRICT_LEADER', 'CITY_LEADER', 'UNIT'],
 'collection': ['SYSTEM_ADMIN', 'DISTRICT_ADMIN', 'CITY_ADMIN', 'DISTRICT_LEADER', 'CITY_LEADER'],
 'supervision': ['DISTRICT_LEADER', 'CITY_LEADER'],
 'notice': ['DISTRICT_ADMIN', 'CITY_ADMIN'],
 'report': ['DISTRICT_LEADER', 'CITY_LEADER']
 };

 const allowedRoles = menuPermissions[menuId] || [];
 return allowedRoles.includes(this.currentUser.role);
 }

 /**
 * 获取用户角色名称
 */
 getRoleName(): string {
 if (!this.currentUser) {
 return '';
 }
 const roleNames: Record<string, string> = {
 'SYSTEM_ADMIN': '系统管理员',
 'DISTRICT_ADMIN': '区级管理员',
 'CITY_ADMIN': '市级管理员',
 'DISTRICT_LEADER': '区级领导',
 'CITY_LEADER': '市级领导',
 'UNIT': '单位负责人'
 };
 return roleNames[this.currentUser.role] || '';
 }

 /**
 * 判断是否为管理员角色
 */
 isAdmin(): boolean {
 if (!this.currentUser) {
 return false;
 }
 return ['SYSTEM_ADMIN', 'DISTRICT_ADMIN', 'CITY_ADMIN'].includes(this.currentUser.role);
 }

 /**
 * 判断是否为领导角色
 */
 isLeader(): boolean {
 if (!this.currentUser) {
 return false;
 }
 return ['DISTRICT_LEADER', 'CITY_LEADER'].includes(this.currentUser.role);
 }

 /**
 * 判断是否为单位角色
 */
 isUnit(): boolean {
 return this.currentUser?.role === 'UNIT';
 }
}

// 导出全局实例
export const appViewModel = AppViewModel.getInstance();
