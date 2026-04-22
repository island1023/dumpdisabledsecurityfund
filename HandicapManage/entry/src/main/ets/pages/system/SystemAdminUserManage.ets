import { ColorConstants } from '../../common/constants/ColorConstants';
import { SystemUserService, ImportResult, CompanyOption } from '../../services/SystemUserService';
import { User } from '../../models/UserModel';
import { promptAction } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';

@Component
export struct SystemAdminUserManage {
  @State userList: User[] = [];
  @State searchKeyword: string = '';
  @State showAddDialog: boolean = false;
  @State showPasswordDialog: boolean = false;
  @State activeSheet: string = ''; // 用于控制当前显示的弹窗
  @State newPassword: string = '';
  @State formUsername: string = '';
  @State formRealName: string = '';
  @State formRole: string = '';
  @State formDistrict: string = '';
  @State formCompanyId: string = '';
  @State formCompanyName: string = '';
  @State showRoleDropdown: boolean = false;
  @State showDistrictDropdown: boolean = false;
  @State showCompanyDropdown: boolean = false;
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State editingUserId: string = '';
  @State isImporting: boolean = false;
  @State companyOptions: CompanyOption[] = [];

  private roleOptions: string[] = [
    'SYSTEM_ADMIN', 'CITY_ADMIN', 'DISTRICT_ADMIN',
    'CITY_LEADER', 'DISTRICT_LEADER', 'UNIT'
  ];

  private districtOptions: string[] = [
    '锦江区', '青羊区', '金牛区', '武侯区', '成华区',
    '龙泉驿区', '青白江区', '新都区', '温江区', '双流区', '郫都区'
  ];

  aboutToAppear() {
    this.loadUserList();
    this.loadCompanyOptions();
  }

  async loadCompanyOptions() {
    try {
      this.companyOptions = await SystemUserService.getCompanyOptions();
    } catch (error) {
      console.error('加载单位列表失败:', error);
    }
  }

  async loadUserList() {
    this.isLoading = true;
    try {
      console.log('开始加载用户列表...');
      const result = await SystemUserService.getUserList({
        pageNum: 1,
        pageSize: 100,
        keyword: this.searchKeyword
      });
      console.log('用户列表加载成功，总数:', result.total, '当前列表数量:', result.list.length);
      if (result.list.length > 0) {
        console.log('第一个用户数据:', JSON.stringify(result.list[0]));
      }
      this.userList = result.list;

      if (result.list.length === 0) {
        console.warn('用户列表为空，可能原因：1.后端没有数据 2.接口返回格式不对');
      }
    } catch (error) {
      this.errorMessage = '加载用户列表失败';
      console.error('加载用户列表失败:', error);
      AlertDialog.show({
        title: '错误',
        message: '加载用户列表失败，请检查：\n1.后端服务是否启动\n2.网络连接是否正常\n3.是否已登录',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        TextInput({ placeholder: '搜索用户名、姓名...', text: this.searchKeyword })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor(ColorConstants.BG_CARD)
          .borderRadius(8)
          .padding({ left: 12, right: 12 });

        Button('搜索')
          .width(70)
          .height(40)
          .fontSize(14)
          .fontColor(ColorConstants.BG_CARD)
          .backgroundColor(ColorConstants.PRIMARY)
          .borderRadius(8)
          .margin({ left: 8 })
          .onClick((): void => {
            this.loadUserList();
          });

        Button('新增')
          .width(70)
          .height(40)
          .fontSize(14)
          .fontColor(ColorConstants.BG_CARD)
          .backgroundColor(ColorConstants.SUCCESS)
          .borderRadius(8)
          .margin({ left: 8 })
          .onClick((): void => {
            console.log('点击新增按钮');
            this.resetAddForm();
            this.activeSheet = 'add';
            this.showAddDialog = true;
          });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(ColorConstants.BG_PAGE);

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.userList.length === 0) {
        Column() {
          Text('暂无用户数据')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY);
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else {
        List() {
          ForEach(this.userList, (user: User) => {
            ListItem() {
              this.buildUserCard(user);
            }
          });
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor(ColorConstants.BG_PAGE);
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showAddDialog, this.sheetBuilder(), {
      detents: this.activeSheet === 'password' ? [SheetSize.MEDIUM] : [SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      showClose: true,
      onDisappear: () => {
        console.log('弹窗关闭');
        this.activeSheet = '';
        this.showPasswordDialog = false;
        this.showRoleDropdown = false;
        this.showDistrictDropdown = false;
        this.showCompanyDropdown = false;
      }
    });
  }

  private closeCurrentSheet(): void {
    this.showAddDialog = false;
    this.showPasswordDialog = false;
    this.showRoleDropdown = false;
    this.showDistrictDropdown = false;
    this.showCompanyDropdown = false;
  }

  @Builder
  sheetBuilder(): void {
    if (this.activeSheet === 'add') {
      this.buildAddDialog();
    } else if (this.activeSheet === 'password') {
      this.buildPasswordDialog();
    } else {
      // 避免状态切换瞬间出现空白面板
      this.buildAddDialog();
    }
  }

  @Builder
  buildUserCard(user: User) {
    Column() {
      Row() {
        Column() {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(24)
            .fontColor([ColorConstants.PRIMARY]);
        }
        .width(40)
        .height(40)
        .backgroundColor('rgba(199, 28, 34, 0.1)')
        .borderRadius(20)
        .justifyContent(FlexAlign.Center);

        Column() {
          Row() {
            Text(user.realName)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.TEXT_TITLE)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis });
          }
          .width('100%');

          Text(this.getRoleName(user.role))
            .fontSize(12)
            .fontColor(this.getRoleColor(user.role))
            .margin({ top: 2 });
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
        .layoutWeight(1);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);

      Row() {
        Column() {
          Text('用户名')
            .fontSize(11)
            .fontColor(ColorConstants.TEXT_SECONDARY);
          Text(user.username)
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_TITLE)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);

        Column() {
          Text('创建时间')
            .fontSize(11)
            .fontColor(ColorConstants.TEXT_SECONDARY);
          Text(user.createTime)
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_TITLE);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%')
      .margin({ top: 12 });

      Row() {
        Button('编辑')
          .width(92)
          .height(32)
          .fontSize(12)
          .fontColor(ColorConstants.PRIMARY)
          .backgroundColor('rgba(199, 28, 34, 0.08)')
          .borderRadius(16)
          .onClick((): void => {
            this.handleEditUser(user);
          });

        Button('重置密码')
          .width(92)
          .height(32)
          .fontSize(12)
          .fontColor(ColorConstants.SUCCESS)
          .backgroundColor('rgba(0, 158, 95, 0.1)')
          .borderRadius(16)
          .onClick((): void => {
            this.handleResetPassword(user.id);
          });

        Button('删除')
          .width(92)
          .height(32)
          .fontSize(12)
          .fontColor(ColorConstants.DANGER)
          .backgroundColor('rgba(166, 32, 25, 0.1)')
          .borderRadius(16)
          .onClick((): void => {
            this.handleDeleteUser(user.id);
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 12 });
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ColorConstants.BG_CARD)
    .borderRadius(12)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
    .border({ width: 1, color: ColorConstants.BORDER });
  }

  @Builder
  buildAddDialog(): void {
    Column() {
      Text(this.editingUserId ? '编辑用户' : '新增用户')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConstants.TEXT_TITLE)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ top: 20, bottom: 16 });

      Scroll() {
        Column() {
          this.buildFormItem('用户名', this.formUsername, (val: string) => { this.formUsername = val; });
          this.buildFormItem('姓名', this.formRealName, (val: string) => { this.formRealName = val; });

          Column() {
            Text('角色')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .margin({ bottom: 8 });

            Row() {
              Text(this.formRole ? this.getRoleName(this.formRole) : '请选择角色')
                .fontSize(14)
                .fontColor(this.formRole ? ColorConstants.TEXT_TITLE : ColorConstants.TEXT_SECONDARY)
                .layoutWeight(1);

              SymbolGlyph($r('sys.symbol.chevron_down'))
                .fontSize(16)
                .fontColor([ColorConstants.TEXT_SECONDARY])
                .rotate({ angle: this.showRoleDropdown ? 180 : 0 });
            }
            .width('100%')
            .height(44)
            .padding({ left: 12, right: 12 })
            .backgroundColor(ColorConstants.BG_PAGE)
            .borderRadius(8)
            .border({ width: 1, color: ColorConstants.BORDER })
            .onClick((): void => {
              this.showRoleDropdown = !this.showRoleDropdown;
              this.showDistrictDropdown = false;
              this.showCompanyDropdown = false;
            });

            if (this.showRoleDropdown) {
              List() {
                ForEach(this.roleOptions, (roleCode: string) => {
                  ListItem() {
                    Row() {
                      Text(this.getRoleName(roleCode))
                        .fontSize(14)
                        .fontColor(this.formRole === roleCode ? ColorConstants.PRIMARY : ColorConstants.TEXT_TITLE)
                        .fontWeight(this.formRole === roleCode ? FontWeight.Bold : FontWeight.Normal)
                        .layoutWeight(1);

                      if (this.formRole === roleCode) {
                        SymbolGlyph($r('sys.symbol.checkmark'))
                          .fontSize(16)
                          .fontColor([ColorConstants.PRIMARY]);
                      }
                    }
                    .width('100%')
                    .height(44)
                    .padding({ left: 12, right: 12 })
                    .onClick((): void => {
                      this.formRole = roleCode;
                      this.showRoleDropdown = false;
                      if (['DISTRICT_ADMIN', 'DISTRICT_LEADER', 'UNIT'].includes(roleCode)) {
                        this.formDistrict = '';
                        this.showDistrictDropdown = true;
                      } else if (['CITY_ADMIN', 'CITY_LEADER'].includes(roleCode)) {
                        this.formDistrict = '成都市';
                        this.showDistrictDropdown = false;
                      } else {
                        this.formDistrict = '';
                        this.showDistrictDropdown = false;
                      }
                      if (roleCode === 'UNIT') {
                        this.formCompanyId = '';
                        this.formCompanyName = '';
                      } else {
                        this.showCompanyDropdown = false;
                      }
                    });
                  }
                });
              }
              .width('100%')
              .height(180)
              .borderRadius(8)
              .border({ width: 1, color: ColorConstants.BORDER })
              .margin({ top: 8 });
            }
          }
          .width('100%')
          .margin({ bottom: 16 });

          if (['DISTRICT_ADMIN', 'DISTRICT_LEADER', 'UNIT'].includes(this.formRole)) {
            Column() {
              Row() {
                Text(this.formDistrict || '所属地区')
                  .fontSize(14)
                  .fontColor(this.formDistrict ? ColorConstants.TEXT_TITLE : ColorConstants.TEXT_SECONDARY)
                  .layoutWeight(1);

                SymbolGlyph($r('sys.symbol.chevron_down'))
                  .fontSize(16)
                  .fontColor([ColorConstants.TEXT_SECONDARY])
                  .rotate({ angle: this.showDistrictDropdown ? 180 : 0 });
              }
              .width('100%')
              .height(44)
              .padding({ left: 12, right: 12 })
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(8)
              .border({ width: 1, color: ColorConstants.BORDER })
              .margin({ bottom: 8 })
              .onClick((): void => {
                this.showDistrictDropdown = !this.showDistrictDropdown;
                this.showCompanyDropdown = false;
              });

              if (this.showDistrictDropdown) {
                List() {
                  ForEach(this.districtOptions, (district: string) => {
                    ListItem() {
                      Row() {
                        Text(district)
                          .fontSize(14)
                          .fontColor(this.formDistrict === district ? ColorConstants.PRIMARY : ColorConstants.TEXT_TITLE)
                          .fontWeight(this.formDistrict === district ? FontWeight.Bold : FontWeight.Normal)
                          .layoutWeight(1);

                        if (this.formDistrict === district) {
                          SymbolGlyph($r('sys.symbol.checkmark'))
                            .fontSize(16)
                            .fontColor([ColorConstants.PRIMARY]);
                        }
                      }
                      .width('100%')
                      .height(44)
                      .padding({ left: 12, right: 12 })
                      .onClick((): void => {
                        this.formDistrict = district;
                        this.showDistrictDropdown = false;
                      });
                    }
                  });
                }
                .width('100%')
                .height(180)
                .borderRadius(8)
                .border({ width: 1, color: ColorConstants.BORDER });
              }
            }
            .width('100%')
            .margin({ bottom: 16 });
          }

          if (this.formRole === 'UNIT') {
            Column() {
              Text('所属单位')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
                .margin({ bottom: 8 });

              Row() {
                Text(this.formCompanyName || '请选择所属单位')
                  .fontSize(14)
                  .fontColor(this.formCompanyName ? ColorConstants.TEXT_TITLE : ColorConstants.TEXT_SECONDARY)
                  .layoutWeight(1);

                SymbolGlyph($r('sys.symbol.chevron_down'))
                  .fontSize(16)
                  .fontColor([ColorConstants.TEXT_SECONDARY])
                  .rotate({ angle: this.showCompanyDropdown ? 180 : 0 });
              }
              .width('100%')
              .height(44)
              .padding({ left: 12, right: 12 })
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(8)
              .border({ width: 1, color: ColorConstants.BORDER })
              .margin({ bottom: 8 })
              .onClick((): void => {
                this.showCompanyDropdown = !this.showCompanyDropdown;
                this.showDistrictDropdown = false;
              });

              if (this.showCompanyDropdown) {
                List() {
                  ForEach(this.companyOptions, (company: CompanyOption) => {
                    ListItem() {
                      Row() {
                        Text(company.name)
                          .fontSize(14)
                          .fontColor(this.formCompanyId === company.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_TITLE)
                          .fontWeight(this.formCompanyId === company.id ? FontWeight.Bold : FontWeight.Normal)
                          .layoutWeight(1);

                        if (this.formCompanyId === company.id) {
                          SymbolGlyph($r('sys.symbol.checkmark'))
                            .fontSize(16)
                            .fontColor([ColorConstants.PRIMARY]);
                        }
                      }
                      .width('100%')
                      .height(44)
                      .padding({ left: 12, right: 12 })
                      .onClick((): void => {
                        this.formCompanyId = company.id;
                        this.formCompanyName = company.name;
                        this.showCompanyDropdown = false;
                      });
                    }
                  });
                }
                .width('100%')
                .height(180)
                .borderRadius(8)
                .border({ width: 1, color: ColorConstants.BORDER });
              }
            }
            .width('100%')
            .margin({ bottom: 16 });
          }

          Button(this.isImporting ? '导入中...' : '通过Excel导入')
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontColor(ColorConstants.PRIMARY)
            .backgroundColor('rgba(199, 28, 34, 0.1)')
            .borderRadius(8)
            .margin({ bottom: 16 })
            .enabled(!this.isImporting)
            .onClick(async (): Promise<void> => {
              await this.handleImportExcel();
            });
        }
        .width('100%');
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .align(Alignment.Top);

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
          .onClick((): void => {
            console.log('取消按钮被点击');
            this.closeCurrentSheet();
          });

        Button('保存')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontColor(ColorConstants.BG_CARD)
          .backgroundColor(ColorConstants.PRIMARY)
          .borderRadius(8)
          .margin({ left: 8 })
          .onClick(async (): Promise<void> => {
            console.log('=== 保存按钮被点击 ===');
            await this.handleSaveUser();
          });
      }
      .width('100%')
      .padding({ top: 16, bottom: 20 });
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
    .height('100%');
  }

  @Builder
  buildPasswordDialog() {
    Column() {
      Text('新密码已生成')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConstants.TEXT_TITLE)
        .margin({ top: 20, bottom: 16 });

      Column() {
        Text('请将以下密码告知用户，并提醒其尽快修改')
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .margin({ bottom: 16 });

        Text(this.newPassword || '123456')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConstants.PRIMARY)
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor('rgba(199, 28, 34, 0.05)')
          .borderRadius(8)
          .width('100%')
          .textAlign(TextAlign.Center)
          .copyOption(CopyOptions.LocalDevice);
      }
      .width('100%')
      .padding({ left: 24, right: 24 });

      Button('我知道了')
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor(ColorConstants.BG_CARD)
        .backgroundColor(ColorConstants.PRIMARY)
        .borderRadius(8)
        .margin({ top: 24, left: 24, right: 24, bottom: 20 })
        .onClick((): void => {
          this.closeCurrentSheet();
          this.newPassword = '';
        });
    }
    .width('100%');
  }

  @Builder
  buildFormItem(label: string, value: string, onChange: (val: string) => void): void {
    Column() {
      Text(label)
        .fontSize(14)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .margin({ bottom: 8 });

      TextInput({ placeholder: '请输入' + label, text: value })
        .onChange(onChange)
        .width('100%')
        .height(44)
        .fontSize(14)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .padding({ left: 12, right: 12 });
    }
    .width('100%')
    .margin({ bottom: 16 });
  }

  private getRoleName(role: string): string {
    const roleMap: Record<string, string> = {
      'SYSTEM_ADMIN': '系统管理员',
      'CITY_ADMIN': '市级管理员',
      'DISTRICT_ADMIN': '区级管理员',
      'CITY_LEADER': '市级领导',
      'DISTRICT_LEADER': '区级领导',
      'UNIT': '单位负责人'
    };
    return roleMap[role] || role;
  }

  private getRoleColor(role: string): string {
    const colorMap: Record<string, string> = {
      'SYSTEM_ADMIN': ColorConstants.PRIMARY,
      'CITY_ADMIN': ColorConstants.SUCCESS,
      'DISTRICT_ADMIN': ColorConstants.WARNING,
      'CITY_LEADER': '#6B7280',
      'DISTRICT_LEADER': '#6B7280',
      'UNIT': ColorConstants.TEXT_TITLE
    };
    return colorMap[role] || ColorConstants.TEXT_TITLE;
  }

  private async handleResetPassword(userId: string) {
    try {
      console.log('重置密码，userId:', userId);
      this.newPassword = await SystemUserService.resetPassword(userId);
      if (!this.newPassword || this.newPassword.trim().length === 0) {
        this.newPassword = '123456';
      }
      this.activeSheet = 'password';
      this.showAddDialog = true;
    } catch (error) {
      console.error('重置密码失败:', error);
      AlertDialog.show({
        title: '错误',
        message: error instanceof Error ? error.message : '重置密码失败，请重试',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    }
  }

  private async handleDeleteUser(userId: string) {
    try {
      await SystemUserService.deleteUser(userId);
      this.loadUserList();
    } catch (error) {
      console.error('删除用户失败:', error);
    }
  }

  async handleSaveUser() {
    if (!this.formUsername.trim() || !this.formRealName.trim() || !this.formRole) {
      AlertDialog.show({
        title: '提示',
        message: '请填写必填项（用户名、姓名、角色）',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
      return;
    }

    if (['DISTRICT_ADMIN', 'DISTRICT_LEADER', 'UNIT'].includes(this.formRole) && !this.formDistrict.trim()) {
      AlertDialog.show({
        title: '提示',
        message: '请选择所属地区',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
      return;
    }
    if (this.formRole === 'UNIT' && !this.formCompanyId.trim()) {
      AlertDialog.show({
        title: '提示',
        message: '请选择所属单位',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
      return;
    }

    try {
      const isEditMode = !!this.editingUserId;
      const userData: Partial<User> = {
        username: this.formUsername,
        realName: this.formRealName,
        role: this.formRole,
        districtName: this.formDistrict || undefined
      };

      if (this.editingUserId) {
        await SystemUserService.updateUser(this.editingUserId, userData);
      } else {
        await SystemUserService.addUser(userData, this.formRole === 'UNIT' ? this.formCompanyId : '');
      }

      this.closeCurrentSheet();

      this.resetAddForm();
      await this.loadUserList();

      AlertDialog.show({
        title: '成功',
        message: isEditMode ? '用户更新成功' : '用户新增成功',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    } catch (error) {
      AlertDialog.show({
        title: '错误',
        message: error instanceof Error ? error.message : '操作失败，请重试',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    }
  }

  private resetAddForm(): void {
    this.editingUserId = '';
    this.formUsername = '';
    this.formRealName = '';
    this.formRole = '';
    this.formDistrict = '';
    this.formCompanyId = '';
    this.formCompanyName = '';
    this.showRoleDropdown = false;
    this.showDistrictDropdown = false;
    this.showCompanyDropdown = false;
  }

  private handleEditUser(user: User): void {
    this.editingUserId = user.id;
    this.formUsername = user.username;
    this.formRealName = user.realName;
    this.formRole = user.role;
    this.formDistrict = user.districtName || '';
    this.formCompanyId = '';
    this.formCompanyName = '';
    this.showRoleDropdown = false;
    this.showDistrictDropdown = false;
    this.showCompanyDropdown = false;
    this.activeSheet = 'add';
    this.showAddDialog = true;
  }

  private async handleImportExcel(): Promise<void> {
    this.isImporting = true;
    try {
      promptAction.showToast({ message: '请选择要导入的Excel文件' });
      const documentPicker = new picker.DocumentViewPicker();
      const options = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['.xlsx', '.xls'];

      const selectedUris: Array<string> = await documentPicker.select(options);
      if (!selectedUris || selectedUris.length === 0) {
        promptAction.showToast({ message: '已取消选择文件' });
        return;
      }

      const fileUri = selectedUris[0];
      const fileName = fileUri.substring(fileUri.lastIndexOf('/') + 1) || 'import.xlsx';

      const result: ImportResult = await SystemUserService.importUsersByExcel(fileUri, fileName);
      await this.loadUserList();
      promptAction.showToast({
        message: `导入完成：成功${result.successCount}条，失败${result.failCount}条`
      });
    } catch (error) {
      console.error('Excel导入失败:', error);
      AlertDialog.show({
        title: '导入失败',
        message: error instanceof Error ? error.message : 'Excel导入失败，请重试',
        primaryButton: {
          value: '确定',
          action: () => {}
        }
      });
    } finally {
      this.isImporting = false;
    }
  }
}