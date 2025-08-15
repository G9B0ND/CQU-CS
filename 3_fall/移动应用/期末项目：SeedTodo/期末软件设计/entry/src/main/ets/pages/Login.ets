import router from '@ohos.router';
import Account from '../model/Account';
import PreferencesUtil from '../common/database/PreferencesUtil';
import CommonConstants from '../common/constants/CommonConstants';
import Folder from '../model/Folder';
import FolderType from '../model/FolderType';
import BackgroundType from '../model/BackgroundType';

@Entry
@Component
struct Login {

  /**
   * 表示用户正在登录或者注册。
   */
  @State
  private isLogin: boolean = true;

  /**
   * 注册时，记录用户的密码。
   */
  @State
  private newPassword: string = '';

  /**
   * 记录当前登录账户信息。
   */
  @State @Watch('getDefaultFolders')
  private account: Account = { username: '', password: '' };

  /**
   * 如果正在注册账户，将在注册成功时自动创建的默认文件夹。
   */
  @State
  private defaultFolders: Array<Folder> = [];

  /**
   * 是否选择自动登录。
   */
  @State
  private isDefaultLogin: boolean = false;


  /**
   * 在此生命周期函数中，检查是否有自动登录数据。
   * 如果有则自动登录。
   */
  public aboutToAppear(): void {
    // 获取自动登录的用户数据。若没有则返回空字符串
    PreferencesUtil.getPreferences(CommonConstants.LOGIN_PREFERENCES, '')
      .then((value: string) => {
        // 若存在自动登录用户，则自动登录
        if ((JSON.parse(value) as string).length !== 0 && Object(router.getParams())?.['isExit']!==true) {
          this.account.username = JSON.parse(value) as string;
          // 进入该用户的“今日代办”文件夹（该文件夹在该用户所有文件夹中索引值最小，因此通过查找即可获取）
          PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
            .then((value: string) => {
              let folders: Array<Folder> = JSON.parse(value) as Array<Folder>;
              router.replaceUrl({
                url: 'pages/MyDay',
                params: {
                  folder: folders.find((value: Folder) => value.owner === this.account.username)
                }
              });
            });
        }
      });
  }


  /**
   * account 改变时触发。为注册成功的用户创建默认文件夹。
   */
  public getDefaultFolders(): void {
    this.defaultFolders = [{
      owner: this.account.username,
      folderName: '今日代办',
      folderType: FolderType.MY_DAY,
      background: $r('app.color.default_my_day_bg'),
      backgroundType: BackgroundType.COLOR
    },
      {
        owner: this.account.username,
        folderName: '重要',
        folderType: FolderType.IMPORTANT,
        background: $r('app.color.default_important_bg'),
        backgroundType: BackgroundType.COLOR
      },
      {
        owner: this.account.username,
        folderName: '紧急',
        folderType: FolderType.URGENT,
        background: $r('app.color.default_urgent_bg'),
        backgroundType: BackgroundType.COLOR
      },
      {
        owner: this.account.username,
        folderName: '计划中',
        folderType: FolderType.IN_PLAN,
        background: $r('app.color.default_in_plan_bg'),
        backgroundType: BackgroundType.COLOR
      },
      {
        owner: this.account.username,
        folderName: '全部日程',
        folderType: FolderType.ALL,
        background: $r('app.color.default_all_bg'),
        backgroundType: BackgroundType.COLOR
      }
    ];
  }

  public build(): void {
    Column() {
      Image($r('app.media.seedtodo'))
        .size({width:'50%'})
        .margin({ top: '20%', bottom: '4%' });
      Image($r('app.media.seed'))
        .size({ width: 150, height: 150 });
      Column({ space: 4 }) {
        Text('用户名')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.font_black'))
          .alignSelf(ItemAlign.Start)
          .margin({top:'4%'});
        TextInput({ text: this.account.username })
          .type(InputType.PhoneNumber)
          .onChange((value: string) => {
            this.account.username = value;
          });

        if (this.isLogin) {
          Text('密码')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .alignSelf(ItemAlign.Start)
            .margin({top:'4%'});
          TextInput({ text: this.account.password })
            .type(InputType.Password)
            .onChange((value: string) => {
              this.account.password = value;
            });
          Text('注册新账户')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_grey'))
            .alignSelf(ItemAlign.Start)
            .onClick(() => {
              this.isLogin = false;
              this.account = { username: '', password: '' };
              this.newPassword = '';
            })
            .margin({top:'2%'});
          Button('       ')
            .backgroundImage($r('app.media.log'))
            .backgroundImageSize({width:'90%',height:'90%'})
            .backgroundImagePosition(4)
            .fontSize(25)
            .fontColor(Color.Green)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              PreferencesUtil.getPreferences(CommonConstants.ACCOUNT_PREFERENCES, [])
                .then((value: string) => {
                  let accounts: Array<Account> = JSON.parse(value) as Array<Account>;
                  let account: Account | undefined = accounts.find((account: Account): boolean => {
                    return account.username === this.account.username;
                  });
                  console.debug('[hxk] Login account: ' + JSON.stringify(account));
                  if (account === undefined || account.password !== this.account.password) {
                    AlertDialog.show({
                      message: '用户名或密码错误'
                    });
                  } else {
                    PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
                      .then((value: string) => {
                        if (this.isDefaultLogin) {
                          PreferencesUtil.savePreferences(CommonConstants.LOGIN_PREFERENCES, this.account.username);
                        } else {
                          PreferencesUtil.savePreferences(CommonConstants.LOGIN_PREFERENCES, '');
                        }
                        console.debug('[hxk] Login defaultFolder: ' + JSON.stringify(this.defaultFolders[0]));
                        let folders: Array<Folder> = JSON.parse(value) as Array<Folder>;
                        router.replaceUrl({
                          url: 'pages/MyDay',
                          params: {
                            folder: folders.find((value: Folder) => value.owner === this.account.username)
                          }
                        });
                      });
                  }
                });
            });
        } else {
          Text('密码')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .alignSelf(ItemAlign.Start)
            .margin({top:'4%'});
          TextInput()
            .type(InputType.Password)
            .onChange((value: string) => {
              this.account.password = value;
            });
          Text('请重复密码')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .alignSelf(ItemAlign.Start)
            .margin({top:'4%'});
          TextInput({ text: this.newPassword })
            .type(InputType.Password)
            .onChange((value: string) => {
              this.newPassword = value;
            });
          Text('使用已有账户登录')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_grey'))
            .alignSelf(ItemAlign.Start)
            .onClick(() => {
              this.isLogin = true;
              this.account = { username: '', password: '' };
              this.newPassword = '';
            });
          Button('       ')
            .backgroundImage($r('app.media.register'))
            .backgroundImageSize({width:'90%',height:'90%'})
            .backgroundImagePosition(4)
            .fontSize(20)
            .backgroundColor(Color.Transparent)
            .enabled(this.account.password === this.newPassword && this.newPassword.length > 2)
            .onClick(() => {
              PreferencesUtil.getPreferences(CommonConstants.ACCOUNT_PREFERENCES, [])
                .then((value: string) => {
                  let accounts: Array<Account> = JSON.parse(value) as Array<Account>;
                  console.debug('[hxk] Login accounts: ' + JSON.stringify(accounts));
                  let account: Account | undefined = accounts.find((account: Account): boolean => {
                    return account.username === this.account.username;
                  });
                  if (account !== undefined) {
                    AlertDialog.show({
                      message: '账户已存在'
                    });
                  } else {
                    accounts.push(this.account);
                    PreferencesUtil.savePreferences(CommonConstants.ACCOUNT_PREFERENCES, accounts);
                    if (this.isDefaultLogin) {
                      PreferencesUtil.savePreferences(CommonConstants.LOGIN_PREFERENCES, this.account.username);
                    } else {
                      PreferencesUtil.savePreferences(CommonConstants.LOGIN_PREFERENCES, '');
                    }
                    PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
                      .then((value: string) => {
                        let folders: Array<Folder> = JSON.parse(value) as Array<Folder>;
                        folders = folders.concat(this.defaultFolders);
                        PreferencesUtil.savePreferences(CommonConstants.FOLDER_PREFERENCES, folders);
                        router.replaceUrl({
                          url: 'pages/MyDay',
                          params: {
                            folder: this.defaultFolders[0]
                          }
                        });
                      });
                  }
                });
            })
            .margin({top:'2%'});
        }
        Row() {
          Text('下次自动登录')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_grey'));
          Checkbox()
            .onChange((isOn: boolean) => this.isDefaultLogin = isOn);
        }
        .margin({bottom:'4%'});
      }
      .border({
        radius: 12,
        color: $r('app.color.font_grey'),
        style: BorderStyle.Solid
      })
      .padding('5%')
      .margin('6%')
      .backgroundImage($r('app.media.logbackground'))
      .backgroundImageSize({width:'100%',height:'100%'})
      .shadow({
        radius: 4,
        color: `rgba(0,0,0,0.3)`,
        offsetX:10,
        offsetY:10
      });
    }
    .size({ width: '100%', height: '100%' })
    .backgroundImage($r('app.media.backgroundedit'))
    .backgroundImageSize({width:'100%',height:'100%'})
  }
}