import { ColorConstants } from '../common/constants/ColorConstants';
import { appViewModel } from '../viewmodel/AppViewModel';
import { router } from '@kit.ArkUI';
import { AuthService } from '../services/AuthService';
import { promptAction } from '@kit.ArkUI';
import { HeaderBar, DistrictItem } from '../common/components/NavigationComponents';
import { HomePage } from './home/HomePage';
import { SystemManagePage } from './system/SystemManagePage';
import { UnitHomePage } from './unit/UnitHomePage';
import { CollectionPage } from './collection/CollectionPage';
import { SupervisionPage } from './supervision/SupervisionPage';
import { NoticePage } from './notice/NoticePage';
import { ReportPage } from './report/ReportPage';
import { ApprovalPendingPage } from './approval/ApprovalPendingPage';
import { LeaderArchivePage } from './leader/LeaderArchivePage';
import { LeaderFundUsagePage } from './leader/LeaderFundUsagePage';
import { LeaderReportPage } from './leader/LeaderReportPage';

// 弹窗类型枚举
enum CustomSheetType {
  NONE,
  LOGOUT,
  PROFILE
}

interface TabItem {
  id: string;
  name: string;
  icon: string;
  activeIcon: string;
  roles: string[];
}

/**
 * 主页面 - 移动端适配
 */
@Entry
@Component
struct MainPage {
  @State currentMenu: string = 'home';
  /** 单位主页刷新信号：页面每次显示时递增，驱动 UnitHomePage 重新拉数 */
  @State unitRefreshNonce: number = 0;
  @State isSheetShow: boolean = false;
  @State activeSheet: CustomSheetType = CustomSheetType.NONE;
  @State selectedDistrict: string = 'all'; // 当前选中的区，'all'表示全市
  @State profileUsername: string = '';
  @State profileOldPassword: string = '';
  @State profilePassword: string = '';
  @State profileConfirmPassword: string = '';
  @State profileSaving: boolean = false;
  @State profileError: string = '';

  // 区列表（模拟数据）
  private districtList: DistrictItem[] = [
    { code: '510104', name: '锦江区' },
    { code: '510105', name: '青羊区' },
    { code: '510106', name: '金牛区' },
    { code: '510107', name: '武侯区' },
    { code: '510108', name: '成华区' },
    { code: '510112', name: '龙泉驿区' },
    { code: '510113', name: '青白江区' },
    { code: '510114', name: '新都区' },
    { code: '510115', name: '温江区' },
    { code: '510116', name: '双流区' },
    { code: '510117', name: '郫都区' }
  ];

  // Tab配置
  private tabItems: TabItem[] = [
    {
      id: 'unit',
      name: '单位主页',
      icon: 'house',
      activeIcon: 'house.fill',
      roles: ['UNIT']
    },
    { 
      id: 'system', 
      name: '系统管理', 
      icon: 'gear',
      activeIcon: 'gear.fill',
      roles: ['SYSTEM_ADMIN'] 
    },
    { 
      id: 'approval', 
      name: '待审批', 
      icon: 'doc.text',
      activeIcon: 'doc.text.fill',
      roles: ['DISTRICT_ADMIN', 'CITY_ADMIN'] 
    },
    { 
      id: 'collection', 
      name: '征收核算', 
      icon: 'calculator',
      activeIcon: 'calculator.fill',
      roles: ['DISTRICT_ADMIN', 'CITY_ADMIN'] 
    },
    { 
      id: 'notice', 
      name: '通知单管理', 
      icon: 'printer',
      activeIcon: 'printer.fill',
      roles: ['DISTRICT_ADMIN', 'CITY_ADMIN', 'DISTRICT_LEADER', 'CITY_LEADER'] 
    },
    { 
      id: 'archive', 
      name: '单位档案', 
      icon: 'house',
      activeIcon: 'house.fill',
      roles: ['DISTRICT_LEADER', 'CITY_LEADER'] 
    },
    { 
      id: 'fund', 
      name: '残保金使用', 
      icon: 'person',
      activeIcon: 'person.fill',
      roles: ['DISTRICT_LEADER', 'CITY_LEADER'] 
    },
    { 
      id: 'report', 
      name: '统计报表', 
      icon: 'doc_plaintext',
      activeIcon: 'doc_plaintext.fill',
      roles: ['DISTRICT_LEADER', 'CITY_LEADER'] 
    }
  ];

  private isUnitAccount(): boolean {
    const user = appViewModel.currentUser;
    if (!user) {
      return false;
    }
    const role = (user.role || '').trim().toLowerCase();
    const username = (user.username || '').trim().toLowerCase();
    return role === 'unit' || role === 'company' || role.includes('unit') || role.includes('company') || username.startsWith('unit');
  }

  aboutToAppear() {
    if (!appViewModel.isLoggedIn) {
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }
    // 系统管理员直接进入系统管理页面
    const userRole = appViewModel.currentUser?.role || '';
    if (this.isUnitAccount()) {
      this.currentMenu = 'unit';
    } else if (userRole === 'SYSTEM_ADMIN') {
      this.currentMenu = 'system';
    } else if (userRole === 'DISTRICT_ADMIN' || userRole === 'CITY_ADMIN') {
      // 市/区级管理员直接进入待审批页面
      this.currentMenu = 'approval';
    } else if (userRole === 'DISTRICT_LEADER' || userRole === 'CITY_LEADER') {
      // 市/区领导直接进入单位档案页面
      this.currentMenu = 'archive';
    } else {
      this.currentMenu = appViewModel.currentMenu || 'home';
    }
  }

  onPageShow(): void {
    if (appViewModel.isLoggedIn && appViewModel.currentUser?.role === 'UNIT') {
      this.unitRefreshNonce++;
    }
  }

  getVisibleTabs(): TabItem[] {
    if (this.isUnitAccount()) {
      return this.tabItems.filter(item => item.id === 'unit');
    }
    const userRole = appViewModel.currentUser?.role || '';
    return this.tabItems.filter(item => item.roles.includes(userRole));
  }

  handleLogout() {
    appViewModel.logout();
    AppStorage.setOrCreate('token', '');
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  getPageTitle(): string {
    const titles: Record<string, string> = {
      'unit': '单位主页',
      'system': '系统管理',
      'approval': '待审批',
      'collection': '征收核算',
      'notice': '通知单管理',
      'report': '统计报表',
      'archive': '单位档案',
      'fund': '残保金使用'
    };
    return titles[this.currentMenu] || '单位档案';
  }

  @Builder
  buildPageContent() {
    if (this.isUnitAccount()) {
      UnitHomePage({ refreshNonce: this.unitRefreshNonce })
    } else if (this.currentMenu === 'unit') {
      UnitHomePage({ refreshNonce: this.unitRefreshNonce })
    } else if (this.currentMenu === 'system') {
      SystemManagePage()
    } else if (this.currentMenu === 'approval') {
      ApprovalPendingPage()
    } else if (this.currentMenu === 'collection') {
      CollectionPage()
    } else if (this.currentMenu === 'notice') {
      NoticePage()
    } else if (this.currentMenu === 'report') {
      // 领导角色使用LeaderReportPage，管理员角色使用ReportPage
      if (appViewModel.currentUser?.role === 'DISTRICT_LEADER' || appViewModel.currentUser?.role === 'CITY_LEADER') {
        LeaderReportPage()
      } else {
        ReportPage()
      }
    } else if (this.currentMenu === 'archive') {
      LeaderArchivePage()
    } else if (this.currentMenu === 'fund') {
      LeaderFundUsagePage()
    } else {
      LeaderArchivePage()
    }
  }

  // 获取tab图标（未选中状态）
  private getTabIcon(tabId: string): Resource {
    switch (tabId) {
      case 'unit': return $r('sys.symbol.house');
      case 'system': return $r('sys.symbol.gearshape');
      case 'approval': return $r('sys.symbol.doc_text');
      case 'collection': return $r('sys.symbol.calculator');
      case 'notice': return $r('sys.symbol.printer');
      case 'archive': return $r('sys.symbol.house');
      case 'fund': return $r('sys.symbol.person');
      case 'report': return $r('sys.symbol.doc_plaintext');
      default: return $r('sys.symbol.gearshape');
    }
  }

  // 获取tab激活图标
  private getTabActiveIcon(tabId: string): Resource {
    switch (tabId) {
      case 'unit': return $r('sys.symbol.house_fill');
      case 'system': return $r('sys.symbol.gearshape_fill');
      case 'approval': return $r('sys.symbol.doc_text_fill');
      case 'collection': return $r('sys.symbol.calculator_fill');
      case 'notice': return $r('sys.symbol.printer_fill');
      case 'archive': return $r('sys.symbol.house_fill');
      case 'fund': return $r('sys.symbol.person_fill');
      case 'report': return $r('sys.symbol.doc_plaintext_fill');
      default: return $r('sys.symbol.gearshape_fill');
    }
  }

  @Builder
  buildBottomTab(tab: TabItem) {
    Column() {
      SymbolGlyph(this.currentMenu === tab.id ? this.getTabActiveIcon(tab.id) : this.getTabIcon(tab.id))
        .fontSize(24)
        .fontColor([this.currentMenu === tab.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY])

      Text(tab.name)
        .fontSize(10)
        .fontColor(this.currentMenu === tab.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // 打开弹窗
  private openSheet(type: CustomSheetType) {
    if (type === CustomSheetType.PROFILE) {
      this.initProfileForm();
    }
    this.activeSheet = type;
    this.isSheetShow = true;
  }

  build() {
    // 单位用户直接显示UnitHomePage,不使用MainPage的布局
    if (appViewModel.currentUser?.role === 'UNIT') {
      UnitHomePage({ refreshNonce: this.unitRefreshNonce })
    } else {
      Stack() {
        Column() {
          // 顶部标题栏
          HeaderBar({
            title: this.getPageTitle(),
            showBack: false,
            showUser: true,
            showDistrictFilter: this.isCityAdmin(),
            selectedDistrict: this.selectedDistrict,
            districtList: this.districtList,
            user: appViewModel.currentUser || undefined,
            onUserClick: () => {
              this.openSheet(CustomSheetType.LOGOUT);
            },
            onDistrictChange: (code: string) => {
              this.handleDistrictChange(code);
            }
          })

          // 内容区域 - 占满剩余空间
          Column() {
            this.buildPageContent()
          }
          .layoutWeight(1)
          .width('100%')

          // 底部Tab导航栏 - 仅非系统管理员显示
          if (appViewModel.currentUser?.role !== 'SYSTEM_ADMIN') {
            Row() {
              ForEach(this.getVisibleTabs(), (tab: TabItem) => {
                Column() {
                  this.buildBottomTab(tab)
                }
                .layoutWeight(1)
                .height(56)
                .onClick(() => {
                  this.currentMenu = tab.id;
                  appViewModel.switchMenu(tab.id);
                })
              })
            }
            .width('100%')
            .height(56)
            .backgroundColor(ColorConstants.BG_CARD)
            .border({ width: { top: 1 }, color: ColorConstants.BORDER })
          }
        }
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .height('100%')
      .bindSheet($$this.isSheetShow, this.sheetBuilder(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        preferType: SheetType.BOTTOM,
        showClose: true,
        onDisappear: () => {
          this.isSheetShow = false;
          this.activeSheet = CustomSheetType.NONE;
        }
      })
    }
  }

  // 统一弹窗构造器
  @Builder
  sheetBuilder() {
    Column() {
      if (this.activeSheet === CustomSheetType.LOGOUT) {
        this.buildLogoutSheet()
      } else if (this.activeSheet === CustomSheetType.PROFILE) {
        this.buildProfileSheet()
      }
    }
    .padding({ top: 20 })
  }

  @Builder
  buildLogoutSheet() {
    Column() {
      // 用户信息卡片
      Row() {
        Row() {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(32)
            .fontColor([ColorConstants.PRIMARY])
        }
        .width(60)
        .height(60)
        .backgroundColor('rgba(199, 28, 34, 0.1)')
        .borderRadius(30)
        .justifyContent(FlexAlign.Center)

        Column() {
          Text(appViewModel.currentUser?.realName || '管理员')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Text(`ID: ${appViewModel.currentUser?.username || ''}`)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(20)
      .backgroundColor('rgba(199, 28, 34, 0.05)')
      .borderRadius(12)

      List() {
        ListItem() {
          Row() {
            Text('修改账号信息')
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
          }
          .height(56)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.openSheet(CustomSheetType.PROFILE);
          })
        }
        ListItem() {
          Row() {
            Text('退出登录')
              .fontColor(ColorConstants.DANGER)
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
          }
          .height(56)
          .padding({ left: 16, right: 16 })
          .onClick(() => this.handleLogout())
        }
      }
      .backgroundColor(ColorConstants.BG_CARD)
      .borderRadius(12)
      .margin({ top: 20 })
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  buildProfileSheet() {
    Column() {
      Text('用户名（不可修改）')
        .fontSize(12)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 6 });

      TextInput({ placeholder: '用户名', text: this.profileUsername })
        .enabled(false)
        .margin({ bottom: 12 })
        .onChange((v: string) => {
          this.profileUsername = v;
          this.profileError = '';
        });

      Text('旧密码')
        .fontSize(12)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 6 });

      TextInput({ placeholder: '请输入旧密码', text: this.profileOldPassword })
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange((v: string) => {
          this.profileOldPassword = v;
          this.profileError = '';
        });

      Text('新密码')
        .fontSize(12)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 6 });

      TextInput({ placeholder: '请输入新密码', text: this.profilePassword })
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange((v: string) => {
          this.profilePassword = v;
          this.profileError = '';
        });

      Text('确认新密码')
        .fontSize(12)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 6 });

      TextInput({ placeholder: '请再次输入新密码', text: this.profileConfirmPassword })
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange((v: string) => {
          this.profileConfirmPassword = v;
          this.profileError = '';
        });

      if (this.profileError) {
        Text(this.profileError)
          .fontSize(12)
          .fontColor(ColorConstants.DANGER)
          .margin({ bottom: 12 });
      }

      Button(this.profileSaving ? '保存中...' : '保存修改')
        .width('100%')
        .enabled(!this.profileSaving)
        .onClick(() => {
          this.saveProfile();
        })
    }.padding(20)
  }

  private initProfileForm(): void {
    this.profileUsername = appViewModel.currentUser?.username || '';
    this.profileOldPassword = '';
    this.profilePassword = '';
    this.profileConfirmPassword = '';
    this.profileSaving = false;
    this.profileError = '';
  }

  private async saveProfile(): Promise<void> {
    const user = appViewModel.currentUser;
    if (!user) {
      this.profileError = '用户未登录';
      return;
    }
    if (!this.profileOldPassword.trim()) {
      this.profileError = '请输入旧密码';
      return;
    }
    if (!this.profilePassword.trim()) {
      this.profileError = '请输入新密码';
      return;
    }
    if (this.profilePassword.length < 6) {
      this.profileError = '新密码长度不能少于6位';
      return;
    }
    if (!this.profileConfirmPassword.trim()) {
      this.profileError = '请确认新密码';
      return;
    }
    if (this.profilePassword !== this.profileConfirmPassword) {
      this.profileError = '两次输入的新密码不一致';
      return;
    }

    this.profileSaving = true;
    this.profileError = '';
    try {
      const accountType = user.role === 'UNIT' ? 'company' : 'sys';
      const success = await AuthService.changePassword(
        user.id,
        accountType,
        this.profileOldPassword,
        this.profilePassword,
        this.profileConfirmPassword
      );
      if (!success) {
        throw new Error('保存失败');
      }

      this.isSheetShow = false;
      this.activeSheet = CustomSheetType.NONE;
      promptAction.showToast({ message: '密码修改成功' });
    } catch (error) {
      this.profileError = error instanceof Error ? error.message : '修改失败，请重试';
    } finally {
      this.profileSaving = false;
    }
  }

  // 判断是否为市级管理员或市级领导
  private isCityAdmin(): boolean {
    const role = appViewModel.currentUser?.role || '';
    return role === 'CITY_ADMIN' || role === 'CITY_LEADER';
  }

  // 处理区级筛选变更
  private handleDistrictChange(code: string): void {
    this.selectedDistrict = code;
    console.log('筛选区:', code === 'all' ? '全市' : code);
    // 这里可以触发数据刷新，通知各子页面重新加载数据
  }
}
