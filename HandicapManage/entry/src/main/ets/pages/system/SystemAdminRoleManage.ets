import { ColorConstants } from '../../common/constants/ColorConstants';
import { RoleService, Role } from '../../services/RoleService';

/**
 * 系统管理员 - 角色权限管理页面（移动端适配）
 */
@Component
export struct SystemAdminRoleManage {
  @State roleList: Role[] = [];
  @State searchKeyword: string = '';
  @State showDetailSheet: boolean = false;
  @State selectedRole: Role | null = null;
  @State showAddDialog: boolean = false;
  @State showEditDialog: boolean = false;
  @State isLoading: boolean = false;

  // 表单字段
  @State formName: string = '';
  @State formCode: string = '';
  @State formDescription: string = '';
  @State selectedPermissions: string[] = [];

  aboutToAppear() {
    this.loadRoleList();
  }

  async loadRoleList() {
    this.isLoading = true;
    try {
      const roles = await RoleService.getRoleList();
      this.roleList = roles;
      console.log('角色列表加载成功，数量:', roles.length);
    } catch (error) {
      console.error('加载角色列表失败:', error);
      AlertDialog.show({
        title: '错误',
        message: '加载角色列表失败，请检查网络连接',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    } finally {
      this.isLoading = false;
    }
  }

  // 所有可用权限
  private allPermissions: string[] = [
    '用户管理', '角色管理', '单位管理', '单位查看',
    '征收核算', '资金监管', '通知单管理', '统计报表',
    '信息申报', '缴款查看'
  ];

  build() {
    Column() {
      // 搜索栏
      Row() {
        TextInput({ placeholder: '搜索角色名称...', text: this.searchKeyword })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor(ColorConstants.BG_CARD)
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(ColorConstants.BG_PAGE)

      // 角色列表
      List() {
        ForEach(this.getFilteredList(), (role: Role) => {
          ListItem() {
            this.buildRoleCard(role)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(ColorConstants.BG_PAGE)
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showEditDialog, this.buildAddEditDialog('编辑角色'), {
      detents: [SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      showClose: true,
      title: { title: '编辑角色' },
      onDisappear: () => { this.showEditDialog = false; }
    })
  }

  @Builder
  buildRoleCard(role: Role) {
    Column() {
      Row() {
        // 圆形头像 - 使用小人图标
        Row() {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(20)
            .fontColor([role.roleCode === 'SYSTEM_ADMIN' ? ColorConstants.PRIMARY : ColorConstants.SUCCESS])
        }
        .width(40)
        .height(40)
        .backgroundColor(role.roleCode === 'SYSTEM_ADMIN' ? 'rgba(199, 28, 34, 0.1)' : 'rgba(40, 167, 69, 0.1)')
        .borderRadius(20)
        .justifyContent(FlexAlign.Center)

        // 角色信息
        Column() {
          Text(role.roleName)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConstants.TEXT_TITLE)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(role.remark || '暂无描述')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_BODY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Button('编辑')
        .width('100%')
        .height(36)
        .fontSize(13)
        .fontColor(ColorConstants.PRIMARY)
        .backgroundColor('rgba(199, 28, 34, 0.1)')
        .borderRadius(18)
        .onClick(() => {
          this.selectedRole = role;
          this.formName = role.roleName;
          this.formCode = role.roleCode;
          this.formDescription = role.remark || '';
          this.selectedPermissions = [];
          this.showEditDialog = true;
        })
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ColorConstants.BG_CARD)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
    .border({ width: 1, color: ColorConstants.BORDER })
  }



  @Builder
  buildAddEditDialog(title: string) {
    Scroll() {
      Column() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConstants.TEXT_TITLE)
          .margin({ bottom: 20 })
          .width('100%')
          .textAlign(TextAlign.Start)

        this.buildFormItem('角色名称', this.formName, (val: string) => { this.formName = val; })
        this.buildFormItem('角色编码', this.formCode, (val: string) => { this.formCode = val; })
        this.buildFormItem('描述', this.formDescription, (val: string) => { this.formDescription = val; })

        Text('权限配置')
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .margin({ top: 8, bottom: 12 })
          .width('100%')
          .textAlign(TextAlign.Start)

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(this.allPermissions, (perm: string) => {
            Text(perm)
              .fontSize(13)
              .fontColor(this.selectedPermissions.includes(perm) ? ColorConstants.BG_CARD : ColorConstants.TEXT_TITLE)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor(this.selectedPermissions.includes(perm) ? ColorConstants.PRIMARY : ColorConstants.BG_PAGE)
              .borderRadius(16)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.togglePermission(perm);
              })
          })
        }
        .width('100%')

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .backgroundColor(ColorConstants.BG_PAGE)
            .border({ width: 1, color: ColorConstants.BORDER })
            .borderRadius(8)
            .margin({ right: 8 })
            .onClick(() => {
              this.showAddDialog = false;
              this.showEditDialog = false;
            })

          Button('保存')
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor(ColorConstants.BG_CARD)
            .backgroundColor(ColorConstants.PRIMARY)
            .borderRadius(8)
            .margin({ left: 8 })
            .onClick(() => {
              this.handleSaveRole(title === '新增角色');
            })
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  buildFormItem(label: string, value: string, onChange: (val: string) => void) {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .margin({ bottom: 8 })

      TextInput({ placeholder: '请输入' + label, text: value })
        .onChange(onChange)
        .width('100%')
        .height(44)
        .fontSize(14)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  private getFilteredList(): Role[] {
    if (!this.searchKeyword) {
      return this.roleList;
    }
    return this.roleList.filter(role =>
    role.roleName.includes(this.searchKeyword) ||
    role.roleCode.includes(this.searchKeyword)
    );
  }

  private async handleToggleStatus(roleId: string, currentStatus: number) {
    try {
      const newStatus = currentStatus === 1 ? 0 : 1;
      await RoleService.toggleRoleStatus(roleId, newStatus);
      // 刷新列表
      await this.loadRoleList();
      AlertDialog.show({
        title: '成功',
        message: newStatus === 1 ? '角色已启用' : '角色已禁用',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    } catch (error) {
      console.error('切换状态失败:', error);
      AlertDialog.show({
        title: '错误',
        message: '操作失败，请重试',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    }
  }

  private togglePermission(perm: string) {
    const index = this.selectedPermissions.indexOf(perm);
    if (index > -1) {
      this.selectedPermissions.splice(index, 1);
    } else {
      this.selectedPermissions.push(perm);
    }
  }

  private async handleDeleteRole(roleId: string) {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这个角色吗？',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确定',
        action: async () => {
          try {
            // 注意：接口文档中没有删除角色的接口，这里暂时不调用API
            // 如果需要删除功能，需要后端提供对应接口
            AlertDialog.show({
              title: '提示',
              message: '删除功能暂未实现',
              primaryButton: {
                value: '确定',
                action: () => {}
              }
            });
          } catch (error) {
            console.error('删除角色失败:', error);
          }
        }
      }
    });
  }

  private async handleSaveRole(isAdd: boolean) {
    if (!this.formName.trim() || !this.formCode.trim()) {
      AlertDialog.show({
        title: '提示',
        message: '请填写角色名称和角色代码',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
      return;
    }

    try {
      if (isAdd) {
        await RoleService.addRole({
          roleName: this.formName,
          roleCode: this.formCode,
          remark: this.formDescription
        });
        this.showAddDialog = false;
        AlertDialog.show({
          title: '成功',
          message: '角色新增成功',
          primaryButton: {
            value: '确定',
            action: () => {}
          }
        });
      } else {
        if (this.selectedRole) {
          await RoleService.updateRole(this.selectedRole.id, {
            roleName: this.formName,
            roleCode: this.formCode,
            remark: this.formDescription
          });
        }
        this.showEditDialog = false;
        AlertDialog.show({
          title: '成功',
          message: '角色更新成功',
          primaryButton: {
            value: '确定',
            action: () => {}
          }
        });
      }
      // 刷新列表
      await this.loadRoleList();
    } catch (error) {
      console.error('保存角色失败:', error);
      AlertDialog.show({
        title: '错误',
        message: isAdd ? '角色新增失败，请重试' : '角色更新失败，请重试',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
      return; // 失败时不清空表单
    }

    // 成功后清空表单
    this.formName = '';
    this.formCode = '';
    this.formDescription = '';
    this.selectedPermissions = [];
  }
}