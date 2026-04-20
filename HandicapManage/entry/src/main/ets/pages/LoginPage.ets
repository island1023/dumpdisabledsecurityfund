import { ColorConstants } from '../common/constants/ColorConstants';
import { AuthService, CaptchaResponse } from '../services/AuthService';
import { appViewModel } from '../viewmodel/AppViewModel';
import { router } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';

/**
 * 登录页面
 */
@Entry
@Component
struct LoginPage {
 @State username: string = '';
 @State password: string = '';
 @State captcha: string = '';
 @State captchaKey: string = '';
 @State captchaImage: string = '';
 @State loading: boolean = false;
 @State captchaLoading: boolean = false;
 @State showError: boolean = false;
 @State errorMessage: string = '';
 @State rememberPassword: boolean = false;
 @State debugInfo: string = '';

 private dataPreferences: preferences.Preferences | null = null;
 private readonly PREFERENCES_NAME = 'login_preferences';
 private readonly KEY_USERNAME = 'username';
 private readonly KEY_PASSWORD = 'password';
 private readonly KEY_REMEMBER = 'remember_password';

 async aboutToAppear() {
 await this.loadCaptcha();
 await this.loadLoginInfo();
 }

 /**
 * 加载登录信息
 */
 async loadLoginInfo() {
 try {
 const context = getContext(this);
 this.dataPreferences = await preferences.getPreferences(context, this.PREFERENCES_NAME);
 
 const remember = await this.dataPreferences.get(this.KEY_REMEMBER, false) as boolean;
 this.rememberPassword = remember;
 
 if (remember) {
 const savedUsername = await this.dataPreferences.get(this.KEY_USERNAME, '') as string;
 const savedPassword = await this.dataPreferences.get(this.KEY_PASSWORD, '') as string;
 this.username = savedUsername;
 this.password = savedPassword;
 }
 } catch (error) {
 console.error('加载登录信息失败:', error);
 }
 }

 /**
 * 保存登录信息
 */
 async saveLoginInfo() {
 try {
 if (!this.dataPreferences) {
 const context = getContext(this);
 this.dataPreferences = await preferences.getPreferences(context, this.PREFERENCES_NAME);
 }
 
 await this.dataPreferences.put(this.KEY_REMEMBER, this.rememberPassword);
 
 if (this.rememberPassword) {
 await this.dataPreferences.put(this.KEY_USERNAME, this.username);
 await this.dataPreferences.put(this.KEY_PASSWORD, this.password);
 } else {
 await this.dataPreferences.delete(this.KEY_USERNAME);
 await this.dataPreferences.delete(this.KEY_PASSWORD);
 }
 
 await this.dataPreferences.flush();
 } catch (error) {
 console.error('保存登录信息失败:', error);
 }
 }

 /**
 * 加载验证码
 */
 async loadCaptcha() {
 try {
 this.captchaLoading = true;
 this.debugInfo = '请求中...';
 const response = await AuthService.getCaptcha();
 this.debugInfo = '获取成功';
 this.captchaKey = response.captchaKey;
 this.captchaImage = response.captchaImage;
 this.captcha = '';
 this.debugInfo = `图片长度: ${response.captchaImage ? response.captchaImage.length : 0}`;
 } catch (error) {
 this.errorMessage = '获取验证码失败';
 this.captchaImage = '';
 // 详细错误信息
 if (error instanceof Error) {
 this.debugInfo = `错误: ${error.message}`;
 } else {
 this.debugInfo = `错误: ${JSON.stringify(error)}`;
 }
 } finally {
 this.captchaLoading = false;
 }
 }

 /**
 * 执行登录
 */
 async doLogin() {
 // 表单验证
 if (!this.username) {
 this.showError = true;
 this.errorMessage = '请输入用户名';
 return;
 }
 if (!this.password) {
 this.showError = true;
 this.errorMessage = '请输入密码';
 return;
 }
 if (!this.captcha) {
 this.showError = true;
 this.errorMessage = '请输入验证码';
 return;
 }

 this.showError = false;
 this.loading = true;
 this.debugInfo = '登录请求中...';

 try {
 console.log('登录参数 - username:', this.username);
 console.log('登录参数 - captchaKey:', this.captchaKey);
 console.log('登录参数 - captcha:', this.captcha);
 
 const response = await AuthService.login(this.username, this.password, this.captchaKey, this.captcha);
 console.log('登录响应:', JSON.stringify(response));
 
 if (response.success && response.user) {
 this.debugInfo = '登录成功，跳转中...';
 //保存用户信息到全局状态
 appViewModel.setUser(response.user);
 if (response.token) {
 appViewModel.setToken(response.token);
 AppStorage.setOrCreate('token', response.token);
 }
 // 保存登录信息
 await this.saveLoginInfo();
 // 跳转到主页
 router.replaceUrl({
 url: 'pages/MainPage'
 });
 } else {
 this.debugInfo = `登录失败: ${response.message}`;
 this.showError = true;
 this.errorMessage = response.message;
 await this.loadCaptcha();
 }
 } catch (error) {
 console.error('登录异常:', error);
 if (error instanceof Error) {
 this.debugInfo = `登录异常: ${error.message}`;
 } else {
 this.debugInfo = `登录异常: ${JSON.stringify(error)}`;
 }
 this.showError = true;
 this.errorMessage = '登录失败，请检查网络连接';
 await this.loadCaptcha();
 } finally {
 this.loading = false;
 }
 }

 build() {
 Column() {
 //顶部Logo区域
 Column() {
 SymbolGlyph($r('sys.symbol.house_fill'))
 .fontSize(64)
 .fontColor([ColorConstants.NAV_TEXT])
 .margin({ bottom:16 })

 Text('残疾人就业保障金')
 .fontSize(24)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.NAV_TEXT)

 Text('征收及监管系统')
 .fontSize(18)
 .fontColor('rgba(255,255,255,0.9)')
 .margin({ top:4 })
 }
 .width('100%')
 .padding({ top:60, bottom:40 })
 .linearGradient({
 angle:135,
 colors: [
 [ColorConstants.PRIMARY,0.0],
 [ColorConstants.PRIMARY_DARK,1.0]
 ]
 })

 // 登录表单区域
 Column() {
 Text('用户登录')
 .fontSize(20)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.TEXT_TITLE)
 .margin({ bottom:24 })

 // 用户名输入框
 Column() {
 Row() {
 SymbolGlyph($r('sys.symbol.person'))
 .fontSize(20)
 .fontColor([ColorConstants.TEXT_SECONDARY])
 .margin({ right:12 })

 TextInput({ placeholder: '请输入用户名', text: this.username })
 .layoutWeight(1)
 .height(44)
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_BODY)
 .placeholderColor(ColorConstants.TEXT_SECONDARY)
 .backgroundColor(Color.Transparent)
 .border({ width:0 })
 .onChange((value: string) => {
 this.username = value;
 this.showError = false;
 })
 }
 .width('100%')
 .padding({ left:12, right:12 })
 .backgroundColor(ColorConstants.BG_PAGE)
 .borderRadius(8)
 .border({ width:1, color: ColorConstants.BORDER })
 }
 .width('100%')
 .margin({ bottom:16 })

 // 密码输入框
 Column() {
 Row() {
 SymbolGlyph($r('sys.symbol.lock'))
 .fontSize(20)
 .fontColor([ColorConstants.TEXT_SECONDARY])
 .margin({ right:12 })

 TextInput({ placeholder: '请输入密码', text: this.password })
 .layoutWeight(1)
 .height(44)
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_BODY)
 .placeholderColor(ColorConstants.TEXT_SECONDARY)
 .backgroundColor(Color.Transparent)
 .border({ width:0 })
 .type(InputType.Password)
 .onChange((value: string) => {
 this.password = value;
 this.showError = false;
 })
 }
 .width('100%')
 .padding({ left:12, right:12 })
 .backgroundColor(ColorConstants.BG_PAGE)
 .borderRadius(8)
 .border({ width:1, color: ColorConstants.BORDER })
 }
 .width('100%')
 .margin({ bottom:16 })

 // 验证码输入框
 Row() {
 Row() {
 SymbolGlyph($r('sys.symbol.checkmark_shield'))
 .fontSize(20)
 .fontColor([ColorConstants.TEXT_SECONDARY])
 .margin({ right:12 })

 TextInput({ placeholder: '验证码', text: this.captcha })
 .layoutWeight(1)
 .height(44)
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_BODY)
 .placeholderColor(ColorConstants.TEXT_SECONDARY)
 .backgroundColor(Color.Transparent)
 .border({ width:0 })
 .maxLength(4)
 .onChange((value: string) => {
 this.captcha = value;
 this.showError = false;
 })
 }
 .layoutWeight(1)
 .padding({ left:12, right:12 })
 .backgroundColor(ColorConstants.BG_PAGE)
 .borderRadius(8)
 .border({ width:1, color: ColorConstants.BORDER })

 // 验证码图片
 if (this.captchaImage) {
 Image(this.captchaImage)
 .width(100)
 .height(44)
 .margin({ left:12 })
 .borderRadius(8)
 .objectFit(ImageFit.Contain)
 .onClick(() => {
 this.loadCaptcha();
 })
 } else {
 Row() {
 Text(this.captchaLoading ? '刷新中...' : '点击获取')
 .fontSize(14)
 .fontColor(ColorConstants.PRIMARY)
 }
 .width(100)
 .height(44)
 .margin({ left:12 })
 .backgroundColor(ColorConstants.BG_PAGE)
 .borderRadius(8)
 .justifyContent(FlexAlign.Center)
 .onClick(() => {
 this.loadCaptcha();
 })
 }
 }
 .width('100%')
 .margin({ bottom:16 })

 // 记住密码
 Row() {
 Checkbox()
 .select(this.rememberPassword)
 .selectedColor(ColorConstants.PRIMARY)
 .onChange((isChecked: boolean) => {
 this.rememberPassword = isChecked;
 })

 Text('记住密码')
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_BODY)
 .margin({ left:8 })
 }
 .width('100%')
 .margin({ bottom:16 })

 // 错误提示
 if (this.showError) {
 Row() {
 SymbolGlyph($r('sys.symbol.exclamationmark_circle'))
 .fontSize(16)
 .fontColor([ColorConstants.DANGER])
 .margin({ right:8 })

 Text(this.errorMessage)
 .fontSize(12)
 .fontColor(ColorConstants.DANGER)
 }
 .width('100%')
 .margin({ bottom:16 })
 }

 // 调试信息
 if (this.debugInfo) {
 Text(this.debugInfo)
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 .margin({ bottom:8 })
 }

 // 登录按钮
 Button(this.loading ? '登录中...' : '登 录')
 .width('100%')
 .height(48)
 .fontSize(16)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.NAV_TEXT)
 .backgroundColor(ColorConstants.PRIMARY)
 .borderRadius(8)
 .enabled(!this.loading)
 .onClick(() => {
 this.doLogin();
 })
 }
 .width('100%')
 .padding({ left:32, right:32, top:32, bottom:32 })
 .backgroundColor(ColorConstants.BG_CARD)
 .borderRadius(24)
 .layoutWeight(1)

 // 底部信息
 Column() {
 Text('测试账号提示')
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 .margin({ bottom:8 })

 Text('系统管理员: admin | 市级领导: city_leader')
 .fontSize(11)
 .fontColor(ColorConstants.TEXT_SECONDARY)

 Text('密码均为:123456')
 .fontSize(11)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 .margin({ top:4 })
 }
 .width('100%')
 .padding({ bottom:24 })
 .backgroundColor(ColorConstants.BG_CARD)
 }
 .width('100%')
 .height('100%')
 .backgroundColor(ColorConstants.BG_PAGE)
 }
}
