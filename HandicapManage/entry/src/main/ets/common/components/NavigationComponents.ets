import { ColorConstants } from '../constants/ColorConstants';
import { appViewModel } from '../../viewmodel/AppViewModel';
import { User } from '../../models/UserModel';

interface TabItemData {
  id: string;
  name: string;
}

// 区级数据类型
interface DistrictItem {
  code: string;
  name: string;
}

export { TabItemData, DistrictItem };

/**
 * 顶部标题栏组件
 */
@Component
export struct HeaderBar {
  @Prop title: string = '残疾人就业保障金征收及监管系统';
  @Prop showBack: boolean = false;
  @Prop showUser: boolean = true;
  @Prop user?: User;
  @Prop showDistrictFilter: boolean = false; // 是否显示区级筛选器
  @State selectedDistrict: string = 'all'; // 当前选中的区
  @Prop districtList: Array<DistrictItem> = []; // 可选区列表
  @State showDistrictDialog: boolean = false;
  
  onBack?: () => void;
  onUserClick?: () => void;
  onDistrictChange?: (districtCode: string) => void; // 区级筛选回调

  build() {
    Column() {
      Row() {
        if (this.showBack) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([ColorConstants.TEXT_TITLE])
            .onClick(() => {
              if (this.onBack) {
                this.onBack();
              }
            })
            .margin({ right: 12 })
        } else {
          SymbolGlyph($r('sys.symbol.house_fill'))
            .fontSize(32)
            .fontColor([ColorConstants.PRIMARY])
            .margin({ right: 12 })
        }

        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConstants.TEXT_TITLE)
          .layoutWeight(1)

        // 区级筛选器（仅市级管理员显示）
        if (this.showDistrictFilter) {
          Row() {
            Text(this.selectedDistrict === 'all' ? '全市' : this.getDistrictName())
              .fontSize(14)
              .fontColor(ColorConstants.PRIMARY)
              .margin({ right: 8 })
            
            SymbolGlyph($r('sys.symbol.chevron_down'))
              .fontSize(16)
              .fontColor([ColorConstants.PRIMARY])
          }
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('rgba(199, 28, 34, 0.1)')
          .borderRadius(8)
          .margin({ right: 16 })
          .onClick(() => {
            // 点击弹出选择器
            this.showDistrictDialog = true;
          })
        }

        if (this.showUser && this.user) {
          Row() {
            Text(this.user.realName)
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_BODY)
              .margin({ right: 8 })

            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(24)
              .fontColor([ColorConstants.TEXT_SECONDARY])
          }
          .onClick(() => {
            if (this.onUserClick) {
              this.onUserClick();
            }
          })
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(ColorConstants.BG_CARD)
      .border({ width: { bottom: 1 }, color: ColorConstants.BORDER })

      // 区级选择弹窗
      .bindSheet($$this.showDistrictDialog, this.buildDistrictDialog(), {
        detents: [SheetSize.MEDIUM],
        preferType: SheetType.BOTTOM,
        showClose: true,
        title: { title: '选择行政区' },
        onDisappear: () => {
          this.showDistrictDialog = false;
        }
      })
    }
  }

  @Builder
  buildDistrictDialog() {
    Column() {
      List() {
        // 全市选项
        ListItem() {
          Row() {
            Text('全市')
              .fontSize(16)
              .fontColor(ColorConstants.TEXT_TITLE)
              .layoutWeight(1)
            
            if (this.selectedDistrict === 'all') {
              SymbolGlyph($r('sys.symbol.checkmark'))
                .fontSize(20)
                .fontColor([ColorConstants.PRIMARY])
            }
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 16, bottom: 16 })
          .onClick(() => {
            this.selectDistrict('all');
          })
        }

        // 各区选项
        ForEach(this.districtList, (district: DistrictItem) => {
          ListItem() {
            Row() {
              Text(district.name)
                .fontSize(16)
                .fontColor(ColorConstants.TEXT_TITLE)
                .layoutWeight(1)
              
              if (this.selectedDistrict === district.code) {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(20)
                  .fontColor([ColorConstants.PRIMARY])
              }
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 16, bottom: 16 })
            .onClick(() => {
              this.selectDistrict(district.code);
            })
          }
        })
      }
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
  }

  private selectDistrict(code: string): void {
    this.showDistrictDialog = false;
    this.selectedDistrict = code;
    if (this.onDistrictChange) {
      this.onDistrictChange(code);
    }
  }

  private getDistrictName(): string {
    const district = this.districtList.find(d => d.code === this.selectedDistrict);
    return district ? district.name : '全市';
  }
}

/**
 * 底部导航项
 */
interface TabItem {
 id: string;
 name: string;
 icon: string;
 activeIcon: string;
}

/**
 * 底部导航栏组件
 */
@Component
export struct BottomTabBar {
 @Prop tabs: TabItem[] = [];
 @Link activeTab: string;
 onTabChange?: (tabId: string) => void;

 build() {
 Row() {
 ForEach(this.tabs, (tab: TabItem) => {
 Column() {
 SymbolGlyph(this.activeTab === tab.id ? $r('sys.symbol.' + tab.activeIcon.replace('.', '_')) : $r('sys.symbol.' + tab.icon.replace('.', '_')))
 .fontSize(24)
 .fontColor([this.activeTab === tab.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY])

 Text(tab.name)
 .fontSize(12)
 .fontColor(this.activeTab === tab.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
 .margin({ top:4 })
 }
 .layoutWeight(1)
 .height('100%')
 .justifyContent(FlexAlign.Center)
 .onClick(() => {
 this.activeTab = tab.id;
 if (this.onTabChange) {
 this.onTabChange(tab.id);
 }
 })
 })
 }
 .width('100%')
 .height(56)
 .backgroundColor(ColorConstants.BG_CARD)
 .border({ width: { top:1 }, color: ColorConstants.BORDER })
 }
}

/**
 *侧边导航项
 */
interface SideNavItem {
 id: string;
 name: string;
 icon: string;
 badge?: number;
}

/**
 *侧边导航栏组件
 */
@Component
export struct SideNav {
 @Prop items: SideNavItem[] = [];
 @Link activeItem: string;
 onNavChange?: (itemId: string) => void;

 build() {
 Column() {
 // Logo区域
 Row() {
 SymbolGlyph($r('sys.symbol.house_fill'))
 .fontSize(36)
 .fontColor([ColorConstants.PRIMARY])
 .margin({ right:8 })

 Text('残保金系统')
 .fontSize(16)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.NAV_TEXT)
 }
 .width('100%')
 .height(64)
 .padding({ left:16, right:16 })
 .justifyContent(FlexAlign.Start)

 // 导航菜单
 List() {
 ForEach(this.items, (item: SideNavItem) => {
 ListItem() {
 Row() {
 SymbolGlyph($r('sys.symbol.' + item.icon.replace('.', '_')))
 .fontSize(20)
 .fontColor([ColorConstants.NAV_TEXT])
 .margin({ right:12 })

 Text(item.name)
 .fontSize(14)
 .fontColor(ColorConstants.NAV_TEXT)
 .layoutWeight(1)

 if (item.badge && item.badge >0) {
 Text(item.badge.toString())
 .fontSize(12)
 .fontColor(ColorConstants.PRIMARY)
 .backgroundColor(ColorConstants.BG_CARD)
 .padding({ left:6, right:6, top:2, bottom:2 })
 .borderRadius(10)
 }
 }
 .width('100%')
 .height(48)
 .padding({ left:16, right:16 })
 .backgroundColor(this.activeItem === item.id ? ColorConstants.NAV_SELECTED : Color.Transparent)
 .borderRadius(8)
 .onClick(() => {
 this.activeItem = item.id;
 if (this.onNavChange) {
 this.onNavChange(item.id);
 }
 })
 }
 })
 }
 .width('100%')
 .layoutWeight(1)
 .scrollBar(BarState.Off)

 // 用户信息
 Row() {
 SymbolGlyph($r('sys.symbol.person'))
 .fontSize(32)
 .fontColor([ColorConstants.NAV_TEXT])
 .margin({ right:8 })

 Column() {
 Text(appViewModel.currentUser?.realName || '未登录')
 .fontSize(14)
 .fontColor(ColorConstants.NAV_TEXT)
 Text(appViewModel.getRoleName() || '未知角色')
 .fontSize(12)
 .fontColor('rgba(255,255,255,0.7)')
 .margin({ top:2 })
 }
 .alignItems(HorizontalAlign.Start)
 .layoutWeight(1)

 SymbolGlyph($r('sys.symbol.arrow_right'))
 .fontSize(20)
 .fontColor([ColorConstants.NAV_TEXT])
 }
 .width('100%')
 .height(64)
 .padding({ left:16, right:16 })
 }
 .width(220)
 .height('100%')
 .backgroundColor(ColorConstants.NAV_BG)
 }
}

/**
 * 标签页组件
 */
@Component
export struct TabPanel {
 @Prop tabs: Array<TabItemData> = [];
 @Link activeTab: string;
 onTabChange?: (tabId: string) => void;

 build() {
 Row() {
 ForEach(this.tabs, (tab: TabItemData) => {
 Column() {
 Text(tab.name)
 .fontSize(14)
 .fontColor(this.activeTab === tab.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_BODY)
 .fontWeight(this.activeTab === tab.id ? FontWeight.Bold : FontWeight.Normal)

 if (this.activeTab === tab.id) {
 Divider()
 .width(24)
 .height(2)
 .color(ColorConstants.PRIMARY)
 .margin({ top:4 })
 }
 }
 .height('100%')
 .justifyContent(FlexAlign.Center)
 .padding({ left:16, right:16 })
 .onClick(() => {
 this.activeTab = tab.id;
 if (this.onTabChange) {
 this.onTabChange(tab.id);
 }
 })
 })
 }
 .width('100%')
 .height(44)
 .backgroundColor(ColorConstants.BG_CARD)
 .border({ width: { bottom:1 }, color: ColorConstants.BORDER })
 }
}
