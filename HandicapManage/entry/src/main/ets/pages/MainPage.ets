import { ColorConstants } from '../common/constants/ColorConstants';
import { appViewModel } from '../viewmodel/AppViewModel';
import { router } from '@kit.ArkUI';
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
  @State isSheetShow: boolean = false;
  @State activeSheet: CustomSheetType = CustomSheetType.NONE;
  @State selectedDistrict: string = 'all'; // 当前选中的区，'all'表示全市

  // 区列表（模拟数据）
  private districtList: DistrictItem[] = [
    { code: '440103', name: '荔湾区' },
    { code: '440104', name: '越秀区' },
    { code: '440105', name: '海珠区' },
    { code: '440106', name: '天河区' },
    { code: '440111', name: '白云区' },
    { code: '440112', name: '黄埔区' },
    { code: '440113', name: '番禺区' },
    { code: '440114', name: '花都区' },
    { code: '440115', name: '南沙区' },
    { code: '440117', name: '从化区' },
    { code: '440118', name: '增城区' }
  ];

  // Tab配置
  private tabItems: TabItem[] = [
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

  aboutToAppear() {
    if (!appViewModel.isLoggedIn) {
      router.replaceUrl({ url: 'pages/LoginPage' });
      return;
    }
    // 系统管理员直接进入系统管理页面
    const userRole = appViewModel.currentUser?.role || '';
    if (userRole === 'SYSTEM_ADMIN') {
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

  getVisibleTabs(): TabItem[] {
    const userRole = appViewModel.currentUser?.role || '';
    return this.tabItems.filter(item => item.roles.includes(userRole));
  }

  handleLogout() {
    appViewModel.logout();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  getPageTitle(): string {
    const titles: Record<string, string> = {
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
    if (this.currentMenu === 'system') {
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
    this.activeSheet = type;
    this.isSheetShow = true;
  }

  build() {
    // 单位用户直接显示UnitHomePage,不使用MainPage的布局
    if (appViewModel.currentUser?.role === 'UNIT') {
      UnitHomePage()
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
            this.activeSheet = CustomSheetType.PROFILE;
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
      TextInput({ placeholder: '用户名', text: appViewModel.currentUser?.username || '' })
        .margin({ bottom: 12 })
        .onChange((v: string) => {
          if (appViewModel.currentUser) {
            appViewModel.currentUser.username = v;
          }
        })
      
      TextInput({ placeholder: '新密码' })
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange((v: string) => {
          if (appViewModel.currentUser) {
            appViewModel.currentUser.password = v;
          }
        })
      
      Button('保存修改')
        .width('100%')
        .onClick(() => {
          this.isSheetShow = false;
        })
    }.padding(20)
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
