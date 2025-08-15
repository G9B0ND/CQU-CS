import router from '@ohos.router';
import picker from '@ohos.file.picker';
import CommonConstants from '../common/constants/CommonConstants';
import PreferencesUtil from '../common/database/PreferencesUtil';
import ArrayUtil from '../common/util/ArrayUtil';
import Folder from '../model/Folder';
import FolderType from '../model/FolderType';
import scheduleTable from '../common/database/ScheduleTable';
import Schedule from '../model/Schedule';
import BackgroundType from '../model/BackgroundType';
import SortRule from '../model/SortRule';
import { SwiperComponent, SwiperData } from '../view/SwiperComponent';

@Entry
@Component
struct FoldersList {

  dataList:SwiperData[]=[]


  /**
   * 当前登录的用户名。
   */
  @State
  private username: string = '1';

  /**
   * 所有文件夹。包括其他用户的数据。
   */
  @State @Watch('getFolders')
  private allFolders: Array<Folder> = [];

  /**
   * 当前用户的默认文件夹：今日代办、重要、紧急、计划中、全部日程。
   */
  @State
  private defaultFolders: Array<Folder> = [];

  /**
   * 当前用户创建的文件夹。
   */
  @State
  private customFolders: Array<Folder> = [];

  /**
   * 正在创建的新文件夹。
   */
  @State
  private newFolder: Folder = {
    owner: '',
    folderName: '',
    folderType: FolderType.NORMAL,
    background: $r('app.color.default_normal_bg'),
    backgroundType: BackgroundType.COLOR
  };

  /**
   * 所有日程记录。包括其他用户信息。
   */
  @State @Watch('getSchedulesCount')
  private allSchedules: Array<Schedule> = [];

  /**
   * 统计默认文件夹中每类型包含的日程数。
   */
  @State
  private defaultSchedulesCount: Array<number> = [];

  /**
   * 统计用户创建的文件夹各包含的日程数。
   */
  @State
  private customSchedulesCount: Array<number> = [];

  /**
   * 当显示账户信息时账户管理部分高度。属性动画效果。
   */
  @State
  private animationManageAccountTopHeight: string = '94%';

  /**
   * 当显示账户信息时文件夹管理部分高度。属性动画效果。
   */
  @State
  private animationManageAccountBottomHeight: string = '0%';

  /**
   * 当显示文件夹信息时账户管理部分高度。属性动画效果。
   */
  @State
  private animationNewFolderTopHeight: string = '100%'

  /**
   * 当显示文件夹信息时文件夹管理部分高度。属性动画效果。
   */
  @State
  private animationNewFolderBottomHeight: string = '0%';

  /**
   * 创建文件夹时，选择纯色背景的 Scroll 宽度。属性动画效果。
   */
  @State
  private animationScrollStartWidth: string = '100%';

  /**
   * 创建文件夹时，选择照片背景的 Scroll 宽度。属性动画效果。
   */
  @State
  private animationScrollEndWidth: string = '0%';

  /**
   * 每个默认文件夹显示的图标。
   */
  @State
  private defaultFolderIcons: Array<Resource> = [];

  /**
   * 关系型数据库管理。
   */
  private scheduleTable: scheduleTable = new scheduleTable();

  /**
   * 页面跳转动画。
   */
  public pageTransition(): void {
    PageTransitionEnter({ type: RouteType.None, duration: 400 })
      .slide(SlideEffect.Left);
    PageTransitionExit({ type: RouteType.None, duration: 400 })
      .slide(SlideEffect.Left);
  }

  /**
   * 初始化用户名、文件夹、日程记录数据。
   */
  public aboutToAppear(): void {
    this.dataList.push(new SwiperData($r('app.media.swiper1')))
    this.dataList.push(new SwiperData($r('app.media.swiper2')))
    this.dataList.push(new SwiperData($r('app.media.swiper3')))

    if (Object(router.getParams())?.['username']) {
      this.username = Object(router.getParams())['username'];
    }

    // 读取所有文件夹数据
    PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
      .then((value: string) => {
        this.allFolders = JSON.parse(value) as Array<Folder>;
      });

    this.scheduleTable.getRdbStore(() => {
      this.scheduleTable.queryData(SortRule.DEFAULT, (results: Array<Schedule>) => {
        this.allSchedules = results;
      });
    });
  }


  /**
   * allSchedules 改变时触发。
   * 计算默认文件夹和用户创建的文件夹中包含的日程数。
   */
  public getSchedulesCount(): void {
    let schedules: Array<Schedule> = ArrayUtil.subArray(this.allSchedules,
      (value: Schedule): boolean => value.username === this.username);

    // 计算用户传创建的文件夹中日程数。
    this.customFolders.forEach((folder: Folder, index: number) => {
      this.customSchedulesCount[index] = ArrayUtil.subArray(schedules,
        (value: Schedule): boolean => value.folderName === folder.folderName).length;
    });

    // 计算默认文件夹中日程数。
    this.defaultFolders.forEach((folder: Folder) => {
      switch (folder.folderType) {
        case FolderType.MY_DAY:
          this.defaultSchedulesCount[FolderType.MY_DAY] = ArrayUtil.subArray(schedules,
            (value: Schedule): boolean => value.isMyDay).length;
          this.defaultFolderIcons[FolderType.MY_DAY] = $r('app.media.my_day');
          break;
        case FolderType.IMPORTANT:
          this.defaultSchedulesCount[FolderType.IMPORTANT] = ArrayUtil.subArray(schedules,
            (value: Schedule): boolean => value.isImportant).length;
          this.defaultFolderIcons[FolderType.IMPORTANT] = $r('app.media.star');
          break;
        case FolderType.URGENT:
          this.defaultSchedulesCount[FolderType.URGENT] = ArrayUtil.subArray(schedules,
            (value: Schedule): boolean => value.isUrgent).length;
          this.defaultFolderIcons[FolderType.URGENT] = $r('app.media.ic_public_topping');
          break;
        case FolderType.IN_PLAN:
          this.defaultSchedulesCount[FolderType.IN_PLAN] = ArrayUtil.subArray(schedules,
            (value: Schedule): boolean => value.endYear > 0).length;
          this.defaultFolderIcons[FolderType.IN_PLAN] = $r('app.media.in_plan');
          break;
        case FolderType.ALL:
          this.defaultSchedulesCount[FolderType.ALL] = schedules.length;
          this.defaultFolderIcons[FolderType.ALL] = $r('app.media.home');
          break;
        default:
          console.error('[hxk] FoldersList getScheduleCount error.');
          break;
      }
    });
  }

  /**
   * allFolders 改变时触发。
   * 获取默认文件夹和用户创建的文件夹。
   */
  public getFolders(): void {
    let folders: Array<Folder> = ArrayUtil.subArray(this.allFolders,
      (value: Folder): boolean => value.owner === this.username);
    this.defaultFolders = ArrayUtil.subArray(folders,
      (value: Folder): boolean => value.folderType !== FolderType.NORMAL);
    this.customFolders = ArrayUtil.subArray(folders,
      (value: Folder): boolean => value.folderType === FolderType.NORMAL);
  }

  public build(): void {
    Column() {
      Row() {
        Image($r('app.media.seed'))
          .size({ width: 40, height: 40 })
        Image($r('app.media.seedtodo'))
          .size({width:'33%'})
        Blank();
        if (this.animationManageAccountTopHeight === '0%') {
          Image($r('app.media.cancel'))
            .size({ width: 24, height: 24 })
            .fillColor($r('app.color.font_black'))
            .onClick(() => {
              if (this.animationManageAccountTopHeight === '0%') {
                animateTo({ duration: 400, curve: Curve.Smooth }, () => {
                  this.animationManageAccountBottomHeight = '0%';
                  this.animationManageAccountTopHeight = '94%';
                });
              }
            });
        } else {
          Button() {
            Row() {
              Image($r('app.media.ic_public_input_search_black'))
                .size({ width: 24, height: 24 })
                .fillColor($r('app.color.font_black'));
              Text('搜索')
                .fontWeight(FontWeight.Medium)
                .fontSize(16)
                .fontColor($r('app.color.font_black'));
            };
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.pushUrl({
              url: 'pages/SearchSchedule',
              params: {
                username: this.username
              }
            });
          });
        }
      }
      .onClick(() => {
        if (this.animationManageAccountTopHeight === '0%') {
          animateTo({ duration: 400, curve: Curve.Smooth }, () => {
            this.animationManageAccountBottomHeight = '0%';
            this.animationManageAccountTopHeight = '94%';
          });
        }
      })
      .size({ width: '96%', height: '6%' })
      .margin({ top: '12%' });

      Divider()
        .color($r('app.color.font_grey'))
        .margin('2%');

      Column(){
        SwiperComponent({swiperDataStr:JSON.stringify(this.dataList)})
          .margin({bottom:'2%'})

        Button() {
          Row() {
            Image($r('app.media.User'))
              .size({  height: '8%' })
              .clipShape(new Circle({ width: '225px', height: '225px' }))
            Blank()
            Text(this.username)
              .fontWeight(FontWeight.Medium)
              .fontSize(20)
              .fontColor($r('app.color.font_black'));
            Image(this.animationManageAccountTopHeight === '94%'
              ? $r('app.media.ic_public_arrow_down_0')
              : $r('app.media.ic_public_arrow_up_0'))
              .size({ width: 24, height: 24 })
              .fillColor($r('app.color.font_black'));
          }
          .size({ width: '30%'});
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.animationManageAccountTopHeight === '0%') {
            animateTo({ duration: 400, curve: Curve.Smooth }, () => {
              this.animationManageAccountBottomHeight = '0%';
              this.animationManageAccountTopHeight = '94%';
            });
          } else {
            animateTo({ duration: 400, curve: Curve.Smooth }, () => {
              this.animationManageAccountBottomHeight = '94%';
              this.animationManageAccountTopHeight = '0%';
            });
          }
        });
      }
      .margin({top:'5%',bottom:'5%'})

      Column() {
        List() {
          if (this.defaultSchedulesCount.length > 0) {
            ListItemGroup() {
              ForEach(this.defaultFolders, (folder: Folder) => {
                ListItem() {
                  Column(){
                    Row() {
                      if (this.defaultFolderIcons.length > 0) {
                        Image(this.defaultFolderIcons[folder.folderType])
                          .size({ width: 24, height: 24 })
                          .fillColor((folder.backgroundType === BackgroundType.PHOTO)
                            ? $r('app.color.font_grey')
                            : folder.background);
                      }
                      Text(folder.folderName)
                        .fontWeight(FontWeight.Medium)
                        .fontSize(16)
                        .fontColor($r('app.color.font_black'));
                      Blank();
                      Text(this.defaultSchedulesCount[folder.folderType].toString())
                        .fontWeight(FontWeight.Medium)
                        .fontSize(16)
                        .fontColor($r('app.color.font_grey'));
                    }
                    .onClick(() => {
                      router.pushUrl({
                        url: 'pages/MyDay',
                        params: {
                          username: this.username,
                          folder: folder
                        }
                      });
                    })
                    .size({ width: '100%', height: '6%' })

                    /*Divider()
                      .color($r('app.color.font_grey'))
                      .margin('1%');*/
                  }
                }
              }, (folder: Folder): string => JSON.stringify(folder));

            }
            .border({
              radius: 12,
              style: BorderStyle.Solid,
              color: $r('app.color.font_grey')
            })
            .backgroundColor($r('app.color.pure_white'))
            .padding('5%')
            .margin({right:'5%',left:'5%'})

          }


          ListItem() {
            Divider()
              .color($r('app.color.font_grey'))
              .margin('10%');
          };

          if (this.customSchedulesCount.length > 0) {
            ListItemGroup() {
              ForEach(this.customFolders, (folder: Folder, index: number) => {
                ListItem() {
                  Row() {
                    Image($r('app.media.dot_list'))
                      .size({ width: 24, height: 24 })
                      .fillColor((folder.backgroundType === BackgroundType.PHOTO)
                        ? $r('app.color.font_grey')
                        : folder.background);
                    Text(folder.folderName)
                      .fontWeight(FontWeight.Medium)
                      .fontSize(16)
                      .fontColor($r('app.color.font_black'));
                    Blank();
                    Text(this.customSchedulesCount[index].toString())
                      .fontWeight(FontWeight.Medium)
                      .fontSize(16)
                      .fontColor($r('app.color.font_grey'));
                  }
                  .size({ width: '100%', height: '6%' })
                  .onClick(() => {
                    router.pushUrl({
                      url: 'pages/MyDay',
                      params: {
                        username: this.username,
                        folder: folder
                      }
                    });
                  });
                };
              }, (folder: Folder): string => JSON.stringify(folder));
            };
          }

          /*ListItemGroup() {
            ListItem() {
              Column() {
                Row() {
                  Image($r('app.media.new_folder'))
                    .size({ width: 24, height: 24 })
                    .fillColor($r('app.color.blue'))
                    .visibility(this.animationNewFolderTopHeight === '0%'
                      ? Visibility.Hidden : Visibility.Visible);
                  Text('新建列表')
                    .fontWeight(FontWeight.Medium)
                    .fontSize(16)
                    .fontColor($r('app.color.blue'));
                }
                .justifyContent(FlexAlign.Start)
                .size({ width: '100%', height: '6%' })
                .onClick(() => {
                  animateTo({ duration: 400, curve: Curve.Smooth }, () => {
                    this.animationNewFolderTopHeight = '0%'
                    this.animationNewFolderBottomHeight = '100%';
                  });
                });
              }
              .height(this.animationNewFolderTopHeight);
            };
            ListItem() {
              Column() {
                TextInput({ placeholder: '请输入列表标题' })
                  .defaultFocus(true)
                  .fontColor(
                      ((['今日代办', '重要', '紧急', '计划内', '全部'].find(
                        (value: string): boolean => value === this.newFolder.folderName) === undefined)
                      && (this.customFolders.find(
                        (folder: Folder): boolean => folder.folderName === this.newFolder.folderName) === undefined)
                      ) ? Color.Black : Color.Red)
                  .onChange((value: string) => {
                    this.newFolder.folderName = value;
                  });
                Row({ space: 16 }) {
                  Button() {
                    Text('颜色')
                      .fontWeight(FontWeight.Medium)
                      .fontSize(16)
                      .fontColor($r('app.color.blue'))
                      .margin('2%');
                  }
                  .border({ color: $r('app.color.font_grey'), width: 1 })
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    animateTo({ duration: 300, curve: Curve.Rhythm }, () => {
                      this.animationScrollStartWidth = '100%';
                      this.animationScrollEndWidth = '0%';
                    });
                  });
                  Button() {
                    Text('照片')
                      .fontWeight(FontWeight.Medium)
                      .fontSize(16)
                      .fontColor($r('app.color.blue'))
                      .margin('2%');
                  }
                  .border({ color: $r('app.color.font_grey'), width: 1 })
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    animateTo({ duration: 300, curve: Curve.Rhythm }, () => {
                      this.animationScrollStartWidth = '0%';
                      this.animationScrollEndWidth = '100%';
                    });
                  });
                  Button() {
                    Text('自定义')
                      .fontWeight(FontWeight.Medium)
                      .fontSize(16)
                      .fontColor($r('app.color.blue'))
                      .margin('2%');
                  }
                  .border({ color: $r('app.color.font_grey'), width: 1 })
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    try {
                      let PhotoSelectOptions = new picker.PhotoSelectOptions();
                      PhotoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
                      PhotoSelectOptions.maxSelectNumber = 1;
                      let photoPicker = new picker.PhotoViewPicker();
                      photoPicker.select(PhotoSelectOptions).then((PhotoSelectResult) => {
                        console.info('PhotoViewPicker.select successfully, PhotoSelectResult uri: ' +
                        JSON.stringify(PhotoSelectResult));
                        this.newFolder.background = PhotoSelectResult.photoUris[0];
                        this.newFolder.backgroundType = BackgroundType.PHOTO
                      }).catch((err:ESObject) => {
                        console.error('PhotoViewPicker.select failed with err: ' + err);
                      });
                    } catch (err) {
                      console.error('PhotoViewPicker failed with err: ' + err);
                    }
                  });
                }
                .justifyContent(FlexAlign.Center)
                .margin({ top: '2%', bottom: '2%' })
                .size({ width: '100%', height: '6%' });
                Row() {
                  Scroll() {
                    Row({ space: 16 }) {
                      ForEach(CommonConstants.COLORS, (color: Resource) => {
                        Button()
                          .type(ButtonType.Circle)
                          .backgroundColor(color)
                          .padding('2%')
                          .border({ color: $r('app.color.font_grey'), width: 1 })
                          .size(this.newFolder.background === color ?
                            { width: 36, height: 36 } :
                            { width: 28, height: 28 })
                          .onClick(() => {
                            this.newFolder.background = color;
                          })
                          .animation({ duration: 300, curve: Curve.Sharp });
                      }, (color: Resource) => JSON.stringify(color));
                    }
                    .margin({ top: '2%', bottom: '2%' });
                  }
                  .size({ width: this.animationScrollStartWidth })
                  .scrollable(ScrollDirection.Horizontal)
                  .scrollBar(BarState.Off);
                  Scroll() {
                    Row({ space: 16 }) {
                      ForEach(CommonConstants.PHOTOS, (color: Resource) => {
                        Button() {
                          Image(color)
                            .size(this.newFolder.background === color ?
                              { width: 64, height: 64 } :
                              { width: 56, height: 56 })
                            .clip(new Circle(this.newFolder.background === color ?
                              { width: 64, height: 64 } :
                              { width: 56, height: 56 }));
                        }
                        .backgroundColor(Color.Transparent)
                        .type(ButtonType.Circle)
                        .size(this.newFolder.background === color ?
                          { width: 64, height: 64 } :
                          { width: 56, height: 56 })
                        .onClick(() => {
                          this.newFolder.background = color;
                          this.newFolder.backgroundType = BackgroundType.PHOTO
                        })
                        .animation({ duration: 300, curve: Curve.Sharp });
                      }, (color: Resource) => JSON.stringify(color));
                    }
                    .margin({ top: '2%', bottom: '2%' });
                  }
                  .size({ width: this.animationScrollEndWidth })
                  .scrollable(ScrollDirection.Horizontal)
                  .scrollBar(BarState.Off);
                }
                .alignItems(VerticalAlign.Center)
                .size({ width: '100%', height: '6%' });
                Row() {
                  Button('取消')
                    .fontColor($r('app.color.red'))
                    .backgroundColor(Color.Transparent)
                    .onClick(() => {
                      animateTo({ duration: 400, curve: Curve.Smooth }, () => {
                        this.animationNewFolderTopHeight = '100%';
                        this.animationNewFolderBottomHeight = '0%';
                      });
                    });
                  Divider()
                    .vertical(true)
                    .color($r('app.color.font_grey'))
                    .height('48%');
                  Button('创建')
                    .backgroundColor(Color.Transparent)
                    .fontColor($r('app.color.blue'))
                    .enabled(
                      this.newFolder.folderName.length > 0
                      && (['今日代办', '重要', '紧急', '计划内', '全部'].find(
                        (value: string): boolean => value === this.newFolder.folderName) === undefined)
                      && (this.customFolders.find(
                        (folder: Folder): boolean => folder.folderName === this.newFolder.folderName) === undefined))
                    .onClick(() => {
                      this.newFolder.owner = this.username;
                      this.allFolders.push(this.newFolder);
                      PreferencesUtil.savePreferences(CommonConstants.FOLDER_PREFERENCES, this.allFolders);
                      router.replaceUrl({
                        url: 'pages/MyDay',
                        params: {
                          folder: this.newFolder
                        }
                      });
                    });
                }
                .size({ width: '100%', height: '6%' })
                .justifyContent(FlexAlign.SpaceEvenly);
              }
              .height(this.animationNewFolderBottomHeight);
            };
          };*/
        };
      }
      .size({
        width: this.animationManageAccountTopHeight === '0%' ? '0%' : '100%',
        height: this.animationManageAccountTopHeight
      })



      Column() {
        Row() {
          Image($r('app.media.ic_public_back'))
            .size({ width: 24, height: 24 })
            .fillColor($r('app.color.red'))
            .visibility(this.animationManageAccountTopHeight === '0%'
              ? Visibility.Visible : Visibility.Hidden);
          Text('退出账户')
            .fontWeight(FontWeight.Medium)
            .fontSize(16)
            .fontColor($r('app.color.red'));
        }
        .onClick(()=>{
          router.replaceUrl({
            url: 'pages/Login',
            params: {
              isExit:true
            }
          });
        })

        Row() {
          Image($r('app.media.ic_contacts_delete'))
            .size({ width: 24, height: 24 })
            .fillColor($r('app.color.red'))
            .visibility(this.animationManageAccountTopHeight === '0%'
              ? Visibility.Visible : Visibility.Hidden);
          Text('注销账户')
            .fontWeight(FontWeight.Medium)
            .fontSize(16)
            .fontColor($r('app.color.red'));
        }
        .onClick(() => {
          AlertDialog.show({
            message: '注销后，需要重新登录此设备。确认注销吗？',
            alignment: DialogAlignment.Bottom,
            offset: { dx: 0, dy: -24 },
            autoCancel: true,
            primaryButton: {
              value: '取消',
              fontColor: $r('app.color.blue'),
              action: () => {
              }
            },
            secondaryButton: {
              value: '注销',
              fontColor: $r('app.color.red'),
              action: () => {
                PreferencesUtil.deletePreferences(CommonConstants.LOGIN_PREFERENCES);
                PreferencesUtil.savePreferences(CommonConstants.LOGIN_PREFERENCES, '');
                router.replaceUrl({
                  url: 'pages/Login'
                });
              }
            }
          });
        })
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .size({ width: '100%', height: '8%' });

      }
      .size({
        width: this.animationManageAccountBottomHeight === '0%' ? '0%' : '100%',
        height: this.animationManageAccountBottomHeight
      });
    }
    .backgroundImage($r('app.media.backgroundedit'))
    .backgroundImageSize({width:'100%',height:'100%'})
    .size({ width: '100%', height: '100%' })
    .padding({ left: '2%', right: '2%' })
    .expandSafeArea([SafeAreaType.KEYBOARD]);
  }
}