import { ColorConstants } from '../../common/constants/ColorConstants';
import { TabPanel, TabItemData } from '../../common/components/NavigationComponents';
import { SystemAdminUserManage } from './SystemAdminUserManage';
// 权限管理功能已隐藏，暂时不使用
// import { SystemAdminRoleManage } from './SystemAdminRoleManage';

/**
 * 系统管理页面 - 系统管理员专用
 */
@Component
export struct SystemManagePage {
  @State activeTab: string = 'user';

  private tabs: Array<TabItemData> = [
    { id: 'user', name: '用户管理' }
    // 权限管理功能已隐藏
    // { id: 'role', name: '权限管理' }
  ];

  build() {
    Column() {
      TabPanel({
        tabs: this.tabs,
        activeTab: $activeTab
      })

      if (this.activeTab === 'user') {
        SystemAdminUserManage()
      }
      // 权限管理功能已隐藏
      // else {
      //   SystemAdminRoleManage()
      // }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.BG_PAGE)
  }
}