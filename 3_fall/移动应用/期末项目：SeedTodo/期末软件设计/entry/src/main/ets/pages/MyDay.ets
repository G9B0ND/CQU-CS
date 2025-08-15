import router from '@ohos.router'
import CommonConstants from '../common/constants/CommonConstants'
import ClockArea from '../view/ClockArea'
import Schedule from '../model/Schedule'
import scheduleTable from '../common/database/ScheduleTable'
import NewScheduleDialog from '../view/NewScheduleDialog'
import ArrayUtil from '../common/util/ArrayUtil'
import Folder from '../model/Folder'
import FolderType from '../model/FolderType'
import ChangeBackgroundDialog from '../view/ChangeBackgroundDialog'
import PreferencesUtil from '../common/database/PreferencesUtil'
import http from '@ohos.net.http'
import ApiKey from '../common/constants/ApiKey'
import request from '@ohos.request'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'
import WeatherData from '../model/WeatherData'
import type WeatherResult from '../model/WeatherResult'
import WeatherDialog from '../view/WeatherDialog'
import BackgroundType from '../model/BackgroundType'
import reminderAgentManager from '@ohos.reminderAgentManager'
import SortRule from '../model/SortRule'
import SortRuleDialog from '../view/SortRuleDialog'
import SelectFolderDialog from '../view/SelectFolderDialog'
import MusicLoopState from '../model/MusicLoopState'
import GlobalContext from '../common/util/GlobalContext'
import media from '@ohos.multimedia.media'
import common from '@ohos.app.ability.common'

@Entry
@Component
struct MyDay {
  // 数据存储相关信息。
  /**
   * 当前文件夹。
   * 不同文件夹复用同一个页面，因此需要该变量标识当前文件夹。
   */
  @State
  private folder: Folder = {
    owner: '',
    folderName: '',
    folderType: FolderType.NORMAL,
    background: $r('app.color.default_normal_bg'),
    backgroundType: BackgroundType.COLOR
  };


  /**
   * 当前用户的所有日程记录。不包括其他用户的日程。
   */
  @State
  private schedules: Array<Schedule> = [];
  /**
   * 所有日程记录。包括其他用户的日程。改变时自动刷新 schedules 的值。
   */
  @State @Watch('getSchedules')
  private allSchedules: Array<Schedule> = [];

  /**
   * 今天的日期。
   */
  @State
  private today: string = '';

  /**
   * 天气相关信息。
   */
  @State
  private weatherData: WeatherData = {};

  // 动画相关信息
  /**
   * 已完成日程 ScheduleItem 的标准高度。
   * 配合 animationFinishedListHeight 控制已完成日程的动画效果。
   */
  private scheduleItemHeight: string = '10%';
  /**
   * 已完成日程的高度。表现动画效果。
   */
  @State
  private animationFinishedListHeight: string = this.scheduleItemHeight;

  /**
   * 日程清单排序规则。
   */
  @State @Watch('getAllSchedules')
  private currentSortRule: SortRule = SortRule.DEFAULT;

  /**
   * 控制时钟显示。
   */
  @State
  private isClockShow: boolean = true;

  /**
   * 控制音乐显示。
   */
  @State
  private isMusicShow: boolean = true;

  // 批量管理相关信息
  /**
   * 批量管理状态变量。
   */
  @State
  private isBatchEdit: boolean = false;
  /**
   * 在批量管理中被选中的日程。
   */
  @State
  private batchEditList: Array<Schedule> = [];
  /**
   * 标识在批量管理中被选中的日程被复制还是移动。
   */
  @State
  private isBatchMove: boolean = false;
  /**
   * 标识在批量管理中被选中的日程被复制或移动的位置。
   */
  @State @Watch('selectedFolderChanged')
  private batchSelectedFolder: Folder = null!;

  // 音乐播放相关信息。
  /**
   * 音乐播放器。
   */
  @State
  private avPlayer: media.AVPlayer = null!;
  /**
   * 表示音乐循环模式，包括单曲循环、随机播放、顺序循环。
   */
  @State
  private musicLoopState: MusicLoopState = MusicLoopState.SINGLE;
  /**
   * 表示音频播放器的播放状态
   */
  @State
  private playerState: string = '';
  /**
   * 音乐索引。
   */
  private musicIndex: number = 0;

  /**
   * 控制关系型数据库的各项操作。
   */
  private scheduleTable: scheduleTable = new scheduleTable();

  // 对话框控制器
  /**
   * 添加日程对话框。
   */
  private newScheduleDialogController: CustomDialogController = new CustomDialogController({
    autoCancel: false,
    builder: NewScheduleDialog({
      scheduleTable: this.scheduleTable,
      allSchedules: $allSchedules,
      sourceFolder: $folder
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });
  /**
   * 切换背景对话框。
   */
  private changeBackgroundDialogController: CustomDialogController = new CustomDialogController({
    autoCancel: true,
    builder: ChangeBackgroundDialog({
      folder: $folder
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });
  /**
   * 排序规则对话框。
   */
  private sortRuleDialogController: CustomDialogController = new CustomDialogController({
    autoCancel: true,
    builder: SortRuleDialog({
      currentSortRule: $currentSortRule
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });
  /**
   * 批量管理中，选择将日程复制或移动到其他文件夹的文件夹选择对话框。
   */
  private selectFolderDialogController: CustomDialogController = new CustomDialogController({
    autoCancel: true,
    builder: SelectFolderDialog({ sourceFolder: $folder, selectedFolder: $batchSelectedFolder }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });
  /**
   * 天气对话框。
   */
  private weatherDialogController: CustomDialogController = new CustomDialogController({
    autoCancel: true,
    builder: WeatherDialog({
      folder: this.folder,
      weatherData: this.weatherData
    }),
    alignment: DialogAlignment.Center,
    customStyle: true
  });

  /**
   * 页面跳转动画。
   */
  public pageTransition(): void {
    PageTransitionEnter({ type: RouteType.None, duration: 400 })
      .slide(SlideEffect.Right);
    PageTransitionExit({ type: RouteType.None, duration: 400 })
      .slide(SlideEffect.Right);
  }
  /**
   * 初始化日期、天气、播放器、文件夹、关系型数据库数据。
   */
  public aboutToAppear(): void {
    this.getToday();
    this.getAVPlayer();
    this.getWeather();

    if (Object(router.getParams())?.['folder']) {
      this.folder = Object(router.getParams())['folder'] as Folder;
    }

    console.debug('[hxk] MyDay folder: ' + JSON.stringify(this.folder));

    this.scheduleTable.getRdbStore(() => {
      this.getAllSchedules();
    });
  }
  /**
   * 离开页面时，重置音视频播放器。
   */
  public aboutToDisappear(): void {
    if (this.avPlayer.state === 'playing') {
      this.avPlayer.reset();
    }
  }

  public build(): void {
    Stack() {
      Column()
        .visibility(this.folder.backgroundType === BackgroundType.COLOR
          ? Visibility.Visible : Visibility.Hidden)
        .size({ width: '100%', height: '100%' })
        .backgroundColor(this.folder.background);
      Column()
        .visibility(this.folder.backgroundType === BackgroundType.PHOTO
          ? Visibility.Visible : Visibility.Hidden)
        .size({ width: '100%', height: '100%' })
        .backgroundImage(this.folder.background)
        .backgroundImageSize(ImageSize.Cover)
        .opacity(0.8);

      Column() {
        //顶部导航栏
        Row() {
          Button() {
            Image($r('app.media.list'))
              .size({ width: 30, height: 30 })
              .fillColor($r('app.color.font_black'));
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            if (this.avPlayer.state === 'playing') {
              this.avPlayer.reset();
            }
            router.pushUrl({
              url: 'pages/FoldersList',
              params: {
                username: this.folder.owner
              }
            });
          });
          Blank()
          Image($r('app.media.seed'))
            .size({ width: 45, height: 45 })
          Image($r('app.media.seedtodo'))
            .size({width:'38%'})
          Blank()
          Button() {
            Image($r('app.media.ic_gallery_photoedit_more_black'))
              .size({ width: 30, height: 30 })
              .fillColor($r('app.color.font_black'));
          }
          .backgroundColor(Color.Transparent)
          .bindMenu(this.HeaderMenu());
        }
        .size({ width: '100%', height: '4%' })
        .margin({ top: '12%', left: '4%', right: '4%',bottom:'2%' });
        //顶部信息显示
        Column(){
          Row() {
            Text(this.today)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
            Blank()
            Text('天气：' + this.weatherData.weather)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'))
              .onClick(() => {
                this.weatherDialogController.open();
              });
          }
          .size({ width: '100%', height: '8%' })
          .padding({ left: '3%', right: '3%' })
          .margin({top:'2%',bottom:'3%'})
          Blank()
          Row() {
            Blank()
            if(this.folder.folderName=="今日代办"){
              Image($r('app.media.word1'))
                .size({height:'90%'})
            }
            else if(this.folder.folderName=="重要"){
              Image($r('app.media.word2'))
                .size({height:'90%'})
            }
            else if(this.folder.folderName=="紧急"){
              Image($r('app.media.word3'))
                .size({height:'90%'})
            }
            else if(this.folder.folderName=="计划中"){
              Image($r('app.media.word4'))
                .size({height:'90%'})
            }
            else if(this.folder.folderName=="全部日程"){
              Image($r('app.media.word5'))
                .size({height:'90%'})
            }

            Blank()
          }
          .size({width:'80%',height:'40%'})
          //.backgroundColor(Color.Blue)

          Blank()
          Row() {
            Image($r('app.media.title'))
              .size({width:'75%'})
          }
          .margin({bottom:'1%'})
          //.backgroundColor(Color.Brown)
        }
        .size({ width: '100%', height: '14%' })
        .backgroundImage($r('app.media.back'))
        .backgroundImageSize({width:'100%',height:'200%'})
        .shadow({
          radius: 10,
          color: `rgba(0,0,0,0.5)`,
          offsetX:10,
          offsetY:10
        })
        .border({
          radius: 12,
          style: BorderStyle.Solid,
          color: $r('app.color.font_grey')
        })
        .margin({top:'4%'})

        //时钟音乐组件控制单元
        Row({}){
          this.ClockHeader()
          Blank()
          this.MusicHeader()
          Blank()
          this.AddHeader()
        }.size({ width: '100%'})
        .margin({top:'5%',bottom:'5%'})


        //时钟音乐组件单元
        Column(){
          if (this.isClockShow){
            ClockArea()
              .margin({bottom:'2%'})

          }
          if (this.isMusicShow){
            Row() {
              if (this.avPlayer) {
                Button() {
                  Image(this.musicLoopState === MusicLoopState.RANDOM
                    ? $r('app.media.ic_public_random')
                    : this.musicLoopState === MusicLoopState.SINGLE
                      ? $r('app.media.ic_public_single_cycle')
                      : $r('app.media.ic_public_list_cycle'))
                    .size({ width: 28, height: 28 })
                    .fillColor($r('app.color.font_black'));
                }
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.musicLoopState =
                    this.musicLoopState === MusicLoopState.SINGLE
                      ? MusicLoopState.RANDOM
                      : this.musicLoopState === MusicLoopState.RANDOM
                      ? MusicLoopState.ORDERED : MusicLoopState.SINGLE;
                });

                Button() {
                  Image(this.playerState === 'playing'
                    ? $r('app.media.ic_public_pause')
                    : $r('app.media.ic_public_play'))
                    .size({ width: 28, height: 28 })
                    .fillColor($r('app.color.font_black'));
                }
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  if (this.avPlayer.state === 'playing') {
                    this.avPlayer.pause();
                  } else if (this.avPlayer.state === 'paused') {
                    this.avPlayer.play();
                  } else {
                    this.avPlayer.reset();
                  }
                });

                Button() {
                  Image($r('app.media.ic_public_play_last'))
                    .size({ width: 28, height: 28 })
                    .fillColor($r('app.color.font_black'));
                }
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.avPlayer.reset().then(async () => {
                    this.getPrev();
                    let context = getContext(this) as common.UIAbilityContext;
                    let fileDescriptor = await context.resourceManager.getRawFd(CommonConstants.MUSIC[this.musicIndex]);
                    this.avPlayer.fdSrc = fileDescriptor;
                  });
                });

                Button() {
                  Image($r('app.media.ic_public_play_next'))
                    .size({ width: 28, height: 28 })
                    .fillColor($r('app.color.font_black'));
                }
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.avPlayer.reset().then(async () => {
                    this.getNext();
                    let context = getContext(this) as common.UIAbilityContext;
                    let fileDescriptor = await context.resourceManager.getRawFd(CommonConstants.MUSIC[this.musicIndex]);
                    this.avPlayer.fdSrc = fileDescriptor;
                  });
                });
              }
            }
            .shadow({
              radius: 10,
              color: `rgba(0,0,0,0.5)`,
              offsetX:10,
              offsetY:10
            })
            .border({
              radius: 12,
              style: BorderStyle.Solid,
              color: $r('app.color.font_grey')
            })
            .margin('2%')
            .backgroundImage($r('app.media.backmusic'))
            .backgroundImageSize({width: '100%',height:'100%' })
            .opacity(0.8)
            .size({ width: '100%',height:'5%' })
            .justifyContent(FlexAlign.SpaceEvenly);
          }
        }

        List() {
          ListItemGroup() {
            ForEach(ArrayUtil.subArray(this.schedules, (value: Schedule): boolean =>!value.isFinished),
              (schedule: Schedule) => {
                ListItem() {
                  this.ScheduleItem(schedule);
                }
                .swipeAction({
                  start: this.ItemSwipeLeft(schedule),
                  end: this.ItemSwipeRight(schedule),
                  edgeEffect: SwipeEdgeEffect.Spring
                })
                .size({ height: this.scheduleItemHeight });
              }, (schedule: Schedule) => JSON.stringify(schedule));
          };

          if (ArrayUtil.subArray(this.schedules, (value: Schedule): boolean => value.isFinished).length > 0) {
            ListItemGroup({ header: this.ScheduleItemHeader() }) {
              ForEach(ArrayUtil.subArray(this.schedules, (value: Schedule): boolean => value.isFinished === true),
                (schedule: Schedule) => {
                  ListItem() {
                    this.ScheduleItem(schedule);
                  }
                  .visibility(this.animationFinishedListHeight === '0%'
                    ? Visibility.Hidden : Visibility.Visible)
                  .swipeAction({
                    start: this.ItemSwipeLeft(schedule),
                    end: this.ItemSwipeRight(schedule),
                    edgeEffect: SwipeEdgeEffect.Spring
                  })
                  .enabled(this.animationFinishedListHeight === this.scheduleItemHeight)
                  .size({
                    width: this.animationFinishedListHeight === '0%' ? '0%' : '100%',
                    height: this.animationFinishedListHeight
                  });
                }, (schedule: Schedule) => JSON.stringify(schedule));
            };
          }
        }
        .chainAnimation(true)
        .sticky(StickyStyle.Header)
        .edgeEffect(EdgeEffect.Spring)
        .border({ radius: 12, color: $r('app.color.pure_white') })
        .width('100%')
        .height('86%')
        .alignListItem(ListItemAlign.Center)
        .scrollBar(BarState.Auto);
      }
      .margin({ left: '2%', right: '2%'})
      .size({ width: '94%', height: '100%' });

    };
  }

  /**
   * 在批量管理中，当用户选择日程被移动或复制的目标文件夹时的回调函数。
   * 将被选中的日程，即 batchEditList 中的所有日程移动或复制到目标文件夹。
   */
  public selectedFolderChanged(): void {
    if (this.batchSelectedFolder === null) {
      return;
    } else if (this.isBatchMove) {
      let editList: Array<Schedule> = ArrayUtil.copy(this.batchEditList);
      editList.forEach((value: Schedule) => {
        value.folderName = this.batchSelectedFolder.folderName;
        this.scheduleTable.updateData(value, () => {
        });
        this.getAllSchedules();
      });
      this.batchEditList = [];
      this.isBatchEdit = false;
      this.batchSelectedFolder = null!;
    } else {
      let editList: Array<Schedule> = ArrayUtil.copy(this.batchEditList);
      editList.forEach((value: Schedule) => {
        value.folderName = this.batchSelectedFolder.folderName;
        this.scheduleTable.insertData(value, () => {
        });
        this.getAllSchedules();
      });
      this.batchEditList = [];
      this.isBatchEdit = false;
      this.batchSelectedFolder = null!;
    }
  }

  /**
   * 音乐自习室所在的 ListItemGroup 的标题组件。
   */
  @Builder
  private MusicHeader(): void {
    Row() {
      Image($r('app.media.musics'))
        .size({ width: '30%', height: '50%' })
      Blank()
      /*Image($r('app.media.musicheader'))
        .size({  height: '35%' })*/
      Text('音乐自习室')
        .fontWeight(FontWeight.Medium)
        .fontSize(17)
        .fontColor($r('app.color.font_black'));
    }
    .onClick(() => {
      animateTo({ duration: 400, curve: Curve.Smooth },
        () => this.isMusicShow = !this.isMusicShow);
    })
    .padding('1%')
    .size({ width: '35%', height: '6%' })
    .border({
      radius: 12,
      style: BorderStyle.Solid,
      color: $r('app.color.font_grey')
    })
    .shadow({
      radius: 5,
      color: `rgba(0,0,0,0.5)`,
      offsetX:5,
      offsetY:5
    })
    .backgroundColor($r('app.color.pure_white'))
    .opacity(0.8);
  }

  @Builder
  private AddHeader(): void {
    Row() {
      Image($r('app.media.seed2'))
        .size({ width: '100%', height: '75%' })
    }
    .size({ width: '13%', height: '6%' })
    .border({
      radius: 12,
      style: BorderStyle.Solid,
      color: $r('app.color.font_grey')
    })
    .shadow({
      radius: 5,
      color: `rgba(0,0,0,0.5)`,
      offsetX:5,
      offsetY:5
    })
    .backgroundColor($r('app.color.pure_white'))
    .opacity(0.8)
    .onClick(() => {
      this.newScheduleDialogController.open();
    });
  }

  /**
   * 时钟所在的 ListItemGroup 的标题组件。
   */
  @Builder
  private ClockHeader(): void {
    Row() {
      Image($r('app.media.clock'))
        .size({ width: '30%', height: '50%' })
      Blank()
      Text(this.isClockShow ? '隐藏时钟' : '显示时钟')
        .fontWeight(FontWeight.Medium)
        .fontSize(17)
        .fontColor($r('app.color.font_black'));
    }
    .shadow({
      radius: 5,
      color: `rgba(0,0,0,0.5)`,
      offsetX:5,
      offsetY:5
    })
    .padding('1%')
    .size({ width: '35%', height: '6%' })
    .border({
      radius: 12,
      style: BorderStyle.Solid,
      color: $r('app.color.font_grey')
    })

    .backgroundColor($r('app.color.pure_white'))
    .opacity(0.8)
    .onClick(() => {
      animateTo({ duration: 400, curve: Curve.Smooth },
        () => this.isClockShow = !this.isClockShow);
    });
  }

  /**
   * ScheduleItem 所在的 ListItemGroup 的标题组件。
   */
  @Builder
  private ScheduleItemHeader(): void {
    Row() {
      Text('已完成')
        .fontWeight(FontWeight.Medium)
        .fontSize(14)
        .fontColor($r('app.color.font_black'));
    }

    .enabled(!this.isBatchEdit)
    .padding('1%')
    .size({ width: '96%', height: '4%' })
    .border({
      radius: 12,
      style: BorderStyle.Solid,
      color: $r('app.color.font_grey')
    })
    .margin('2%')
    .backgroundColor($r('app.color.pure_white'))
    .opacity(0.8)
    .onClick(() => {
      animateTo({ duration: 400, curve: Curve.Smooth },
        () => this.animationFinishedListHeight =
          this.animationFinishedListHeight === this.scheduleItemHeight
          ? '0%' : this.scheduleItemHeight);
    });
  }

  /**
   * 列表中，每一条日程记录对应一个 ScheduleItem 组件。
   * @param schedule 组件对应的日程记录。
   */
  @Builder
  private ScheduleItem(schedule: Schedule): void {
    Row({ space: '2%' }) {
      if (this.isBatchEdit) {
        Checkbox({ group: 'batchEditGroup' })
          .select(this.batchEditList.findIndex(
            (value: Schedule): boolean => value.id === schedule.id) !== -1)
          .onChange((isOn: boolean) => {
            if (isOn && this.batchEditList.findIndex(
              (value: Schedule): boolean => value.id === schedule.id) === -1) {
              this.batchEditList.push(schedule);
            } else if (!isOn && this.batchEditList.findIndex(
              (value: Schedule): boolean => value.id === schedule.id) !== -1) {
              this.batchEditList.splice(this.batchEditList.findIndex(
                (value: Schedule): boolean => value.id === schedule.id), 1);
            }
          });

        Column() {
          Row({ space: 8 }) {
            Text(schedule.scheduleName)
              .fontSize(16)
              .fontWeight(FontWeight.Normal)
              .fontColor(schedule.isFinished
                ? $r('app.color.font_grey')
                : $r('app.color.font_black'))
              .decoration(schedule.isFinished
                ? {
                    type: TextDecorationType.LineThrough,
                    color: $r('app.color.font_grey')
                  }
                : {
                    type: TextDecorationType.None,
                  });

            if (schedule.isMyDay && this.folder.folderType !== FolderType.MY_DAY) {
              Row() {
                Image($r('app.media.my_day'))
                  .size({ width: 20, height: 20 })
                  .fillColor($r('app.color.font_grey'));
                Text('今日代办')
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.font_grey'));
              };
            }

            Text(schedule.description)
              .fontSize(14)
              .fontWeight(FontWeight.Normal)
              .fontColor($r('app.color.font_grey'));
          };

          Row({ space: 8 }) {
            if (this.folder.folderType !== FolderType.NORMAL) {
              Text(schedule.folderName.length === 0 ? '日程' : schedule.folderName)
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
            }
            if (schedule.steps.length > 0) {
              Text('共' + schedule.steps.length + '步')
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
            }
            if (schedule.endYear > 0) {
              Row() {
                Image($r('app.media.in_plan'))
                  .size({ width: 20, height: 20 })
                  .fillColor($r('app.color.font_grey'));
                Text(this.getEndTimeText(schedule))
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor(
                      new Date(schedule.endYear + '-' + schedule.endMonth + '-' + schedule.endDate).valueOf()
                      + 24 * 60 * 60 * 1000 < new Date().valueOf()
                      ? $r('app.color.red') : $r('app.color.font_grey'));
              };
            }
            if (schedule.remindTime.length > 0) {
              Row() {
                Image($r('app.media.ring'))
                  .size({ width: 20, height: 20 })
                  .fillColor(schedule.isAlarmRemind
                    ? $r('app.color.blue') : $r('app.color.font_grey'));
              };
            }
            if (!ArrayUtil.equalTo(schedule.repeatInterval, [false, false, false, false, false, false, false])) {
              Row() {
                Image($r('app.media.repeat'))
                  .size({ width: 20, height: 20 })
                  .fillColor($r('app.color.font_grey'));
                Text('定期重复')
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.font_grey'));
              };
            }
          }
        }
        .alignItems(HorizontalAlign.Start);
        Blank();
      } else {
        Button() {
          if (schedule.isFinished) {
            Image($r('app.media.circle_filled'))
              .fillColor($r('app.color.blue'))
              .size({ width: 24, height: 24 })
          } else {
            Image($r('app.media.circle'))
              .fillColor($r('app.color.font_grey'))
              .size({ width: 24, height: 24 });
          }
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          let index = this.allSchedules.indexOf(schedule);
          if (index === -1) {
            console.error('[hxk] MyDay no schedule in allSchedules');
          }
          this.allSchedules[index].isFinished = !this.allSchedules[index].isFinished;
          this.getSchedules();
          this.scheduleTable.updateData(this.allSchedules[index], () => {
          });
        });
        Column() {
          Row({ space: 8 }) {
            Text(schedule.scheduleName)
              .fontSize(16)
              .fontWeight(FontWeight.Normal)
              .fontColor(schedule.isFinished
                ? $r('app.color.font_grey')
                : $r('app.color.font_black'))
              .decoration(schedule.isFinished
                ? {
                    type: TextDecorationType.LineThrough,
                    color: $r('app.color.font_grey')
                  }
                : {
                    type: TextDecorationType.None,
                  });

            if (schedule.isMyDay && this.folder.folderType !== FolderType.MY_DAY) {
              Row() {
                Image($r('app.media.my_day'))
                  .size({ width: 20, height: 20 })
                  .fillColor($r('app.color.font_grey'));
                Text('今日代办')
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.font_grey'));
              };
            }

            Text(schedule.description)
              .fontSize(14)
              .fontWeight(FontWeight.Normal)
              .fontColor($r('app.color.font_grey'));
          };

          Row({ space: 8 }) {
            if (this.folder.folderType !== FolderType.NORMAL) {
              Text(schedule.folderName.length === 0 ? '日程' : schedule.folderName)
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
            }
            if (schedule.steps.length > 0) {
              Text('共' + schedule.steps.length + '步')
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
            }
            if (schedule.endYear > 0) {
              Row() {
                Image($r('app.media.in_plan'))
                  .size({ width: 20, height: 20 })
                  .fillColor($r('app.color.font_grey'));
                Text(this.getEndTimeText(schedule))
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor(
                      new Date(schedule.endYear + '-' + schedule.endMonth + '-' + schedule.endDate).valueOf()
                      + 24 * 60 * 60 * 1000 < new Date().valueOf()
                      ? $r('app.color.red') : $r('app.color.font_grey'));
              };
            }
            if (schedule.remindTime.length > 0) {
              Row() {
                Image($r('app.media.ring'))
                  .size({ width: 20, height: 20 })
                  .fillColor(schedule.isAlarmRemind
                    ? $r('app.color.blue') : $r('app.color.font_grey'));
              };
            }

            if (!ArrayUtil.equalTo(schedule.repeatInterval, [false, false, false, false, false, false, false])) {
              Row() {
                Image($r('app.media.repeat'))
                  .size({ width: 20, height: 20 })
                  .fillColor($r('app.color.font_grey'));
                Text('定期重复')
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.font_grey'));
              };
            }
          }
        }
        .alignItems(HorizontalAlign.Start);

        Blank();

        Column() {
          Button() {
            Row() {
              Text('紧急')
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
              Image(schedule.isUrgent
                ? $r('app.media.ic_public_topping_filled')
                : $r('app.media.ic_public_topping'))
                .size({ width: 24, height: 24 })
                .fillColor(schedule.isUrgent
                  ? $r('app.color.red')
                  : $r('app.color.font_grey'));
            };
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            let index = this.allSchedules.indexOf(schedule);
            if (index === -1) {
              console.error('[hxk] MyDay no schedule in allSchedules');
            }
            this.allSchedules[index].isUrgent = !this.allSchedules[index].isUrgent;
            this.getSchedules();
            this.scheduleTable.updateData(this.allSchedules[index], () => {
            });
          });

          Button() {
            Row() {
              Text('重要')
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
              Image(schedule.isImportant
                ? $r('app.media.star_filled')
                : $r('app.media.star'))
                .size({ width: 24, height: 24 })
                .fillColor(schedule.isImportant
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
            };
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            let index = this.allSchedules.indexOf(schedule);
            if (index === -1) {
              console.error('[hxk] MyDay no schedule in allSchedules');
            }
            this.allSchedules[index].isImportant = !this.allSchedules[index].isImportant;
            this.getSchedules();
            this.scheduleTable.updateData(this.allSchedules[index], () => {
            });
          });
        }
        .alignItems(HorizontalAlign.End);
      }
    }
    .opacity(0.95)
    .border({
      radius: 12,
      style: BorderStyle.Solid,
      color: $r('app.color.font_grey')
    })
    .size({ width: '96%' })
    .padding('2%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(VerticalAlign.Center)
    .backgroundImage($r('app.media.backtodo'))
    .backgroundImageSize({width:'100%',height:'100%'})
    .shadow({
      radius: 5,
      color: `rgba(0,0,0,0.5)`,
      offsetX:5,
      offsetY:5
    })
    .onClick(() => {
      if (this.avPlayer.state === 'playing') {
        this.avPlayer.reset();
      }
      router.replaceUrl({
        url: 'pages/EditSchedule',
        params: {
          schedule: schedule,
          folder: this.folder
        }
      });
    });
  }

  /**
   * ListItem 右滑显示的组件。将对应日程移动至（或移出）“今日代办”。
   * @param schedule 组件对应的日程记录
   */
  @Builder
  private ItemSwipeLeft(schedule: Schedule): void {
    Row() {
      Image($r('app.media.my_day'))
        .size({ width: 24, height: 24 })
        .fillColor($r('app.color.pure_white'));
    }
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.blue'))
    .size({ width: '100%', height: '100%' })
    .onClick(() => {
      schedule.isMyDay = !schedule.isMyDay;
      this.allSchedules[this.allSchedules.findIndex(
        (value: Schedule): boolean => value.id === schedule.id)] = schedule;
      this.scheduleTable.updateData(schedule, () => {
      });
      this.getSchedules();
    });
  }

  /**
   * ListItem 左滑显示的组件。将对应日程删除。
   * @param schedule 组件对应的日程记录
   */
  @Builder
  private ItemSwipeRight(schedule: Schedule): void {
    Row() {
      Image($r('app.media.ic_contacts_delete'))
        .size({ width: 24, height: 24 })
        .fillColor($r('app.color.pure_white'));
    }
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.red'))
    .size({ width: '100%', height: '100%' })
    .onClick(() => {
      let index: number = this.allSchedules.findIndex(
        (value: Schedule): boolean => value.id === schedule.id);
      this.allSchedules.splice(index, 1);
      if (schedule.reminderId > 0) {
        reminderAgentManager.cancelReminder(schedule.reminderId);
      }
      this.scheduleTable.deleteData(schedule, () => {
      });
      AlertDialog.show({
        message: '已删除日程',
        autoCancel: true,
        alignment: DialogAlignment.Bottom,
        offset: { dx: 0, dy: -24 },
        primaryButton: {
          value: '撤销',
          fontColor: $r('app.color.blue'),
          action: () => {
            this.scheduleTable.insertData(schedule, (id: number) => {
              schedule.id = id;
              this.allSchedules.push(schedule);
              this.getSchedules();
            });
          }
        }
      });
    });
  }

  /**
   * 页面右上角按钮绑定的菜单栏。
   */
  @Builder
  private HeaderMenu(): void {
    List() {
      if (this.isBatchEdit) {
        ListItem() {
          Row() {
            Image($r('app.media.ic_gallery_photoedit_more_black'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('退出批量管理')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            this.batchEditList = [];
            this.isBatchEdit = false;
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.ic_public_copy'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('复制到文件夹')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            this.isBatchMove = false;
            this.selectFolderDialogController.open();
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.ic_gallery_move_in'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('移动到文件夹')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            this.isBatchMove = true;
            this.selectFolderDialogController.open();
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.star'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('标记为重要')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            let editList: Array<Schedule> = ArrayUtil.copy(this.batchEditList);
            editList.forEach((value: Schedule) => {
              value.isImportant = true;
              this.scheduleTable.updateData(value, () => {
              });
              this.getAllSchedules();
            });
            this.batchEditList = [];
            this.isBatchEdit = false;
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.ic_public_topping'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('标记为紧急')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            let editList: Array<Schedule> = ArrayUtil.copy(this.batchEditList);
            editList.forEach((value: Schedule) => {
              value.isUrgent = true;
              this.scheduleTable.updateData(value, () => {
              });
              this.getAllSchedules();
            });
            this.batchEditList = [];
            this.isBatchEdit = false;
          })
          .size({ height: '4%' });
        }
        .margin('2%');


        ListItem() {
          Row() {
            Image($r('app.media.ic_public_reset_black'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('清空标记')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            let editList: Array<Schedule> = ArrayUtil.copy(this.batchEditList);
            editList.forEach((value: Schedule) => {
              value.isUrgent = false;
              value.isImportant = false;
              this.scheduleTable.updateData(value, () => {
              });
              this.getAllSchedules();
            });
            this.batchEditList = [];
            this.isBatchEdit = false;
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.ic_public_delete_red'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('删除')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            let editList: Array<Schedule> = ArrayUtil.copy(this.batchEditList);
            editList.forEach((value: Schedule) => {
              this.scheduleTable.deleteData(value, () => {
              });
              this.getAllSchedules();
            });
            this.batchEditList = [];
            this.isBatchEdit = false;
          })
          .size({ height: '4%' });
        }
        .margin('2%');
      } else {
        ListItem() {
          Row() {
            Image($r('app.media.pallet'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('更改主题')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            this.changeBackgroundDialogController.open();
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.ailogo'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('AI小助手')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            router.pushUrl({
              url: 'pages/ChatPage'
            });
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.sort'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('排序依据')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            this.sortRuleDialogController.open();
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.ic_gallery_photoedit_more_black'))
              .fillColor($r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('批量管理')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'));
          }
          .onClick(() => {
            this.isBatchEdit = true;
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        if (this.folder.folderType === FolderType.NORMAL) {
          ListItem() {
            Row() {
              Image($r('app.media.ic_public_delete_red'))
                .fillColor($r('app.color.font_black'))
                .size({ width: 24, height: 24 });
              Text('删除列表')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.font_black'));
            }
            .onClick(() => {
              AlertDialog.show({
                message: '确认删除此列表吗？',
                autoCancel: true,
                alignment: DialogAlignment.Bottom,
                offset: { dx: 0, dy: -24 },
                primaryButton: {
                  value: '取消',
                  fontColor: $r('app.color.blue'),
                  action: () => {
                  }
                },
                secondaryButton: {
                  value: '删除',
                  fontColor: $r('app.color.red'),
                  action: () => {
                    this.schedules.forEach((value: Schedule) => {
                      this.scheduleTable.deleteData(value, () => {
                      });
                    });
                    PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
                      .then((value: string) => {
                        let folders: Array<Folder> = JSON.parse(value) as Array<Folder>;
                        folders.splice(folders.findIndex(
                          (value: Folder): boolean =>
                        value.owner === this.folder.owner
                        && value.folderName === this.folder.folderName), 1);
                        PreferencesUtil.savePreferences(CommonConstants.FOLDER_PREFERENCES, folders);
                        if (this.avPlayer.state === 'playing') {
                          this.avPlayer.reset();
                        }
                        router.pushUrl({
                          url: 'pages/FoldersList',
                          params: {
                            username: this.folder.owner
                          }
                        });
                      });
                  }
                }
              })
            })
            .size({ width: '100%', height: '4%' });
          }
          .margin('2%');
        }
      }
    }
    .padding('2%');
  }

  /**
   * 通过网络请求高德地图 API 获取重庆市沙坪坝区实时天气数据。
   */
  private getWeather(): void {
    abilityAccessCtrl.createAtManager()
      .requestPermissionsFromUser(getContext(),
        ['ohos.permission.INTERNET']);
    let httpRequest = http.createHttp();
    httpRequest.on('headersReceive', (header) => {
      console.info('header: ' + JSON.stringify(header));
    });
    httpRequest.request(
      'https://restapi.amap.com/v3/weather/weatherInfo?key=1cfc033b636eb37ab3b8eba82bf2cabd&city=500106',
      (err, data)=>{
        if (!err) {
          console.info('[hxk] MyDay getWeather Result:' + JSON.stringify(data.result));
          this.weatherData = (JSON.parse(data.result as string) as WeatherResult).lives[0];
          httpRequest.off('headersReceive');
          httpRequest.destroy();
        } else {
          console.error('[hxk] MyDay getWeather error:' + JSON.stringify(err));
          httpRequest.off('headersReceive');
          httpRequest.destroy();
        }
      }
    );
  }

  /**
   * allSchedules 改变时触发的回调函数。
   * 自动刷新 schedules 的值。
   * 根据 folder 判断用户和文件夹信息。
   */
  private getSchedules(): void {
    switch (this.folder.folderType) {
      case FolderType.NORMAL:
        this.schedules = ArrayUtil.subArray(this.allSchedules,
          (value: Schedule): boolean =>
          value.username === this.folder.owner
          && value.folderName === this.folder.folderName);
        break;
      case FolderType.MY_DAY:
        this.schedules = ArrayUtil.subArray(this.allSchedules,
          (value: Schedule): boolean => value.username === this.folder.owner && value.isMyDay);
        break;
      case FolderType.IMPORTANT:
        this.schedules = ArrayUtil.subArray(this.allSchedules,
          (value: Schedule): boolean => value.username === this.folder.owner && value.isImportant);
        break;
      case FolderType.URGENT:
        this.schedules = ArrayUtil.subArray(this.allSchedules,
          (value: Schedule): boolean => value.username === this.folder.owner && value.isUrgent);
        break;
      case FolderType.IN_PLAN:
        this.schedules = ArrayUtil.subArray(this.allSchedules,
          (value: Schedule): boolean => value.username === this.folder.owner && value.endYear > 0);
        break;
      case FolderType.ALL:
        this.schedules = ArrayUtil.subArray(this.allSchedules,
          (value: Schedule): boolean => value.username === this.folder.owner);
        break;
    }

    console.debug('[hxk] MyDay allSchedules: ' + JSON.stringify(this.allSchedules));
    console.debug('[hxk] MyDay schedules: ' + JSON.stringify(this.schedules));
  }

  /**
   * 初始化音频播放器。
   */
  private async getAVPlayer(): Promise<void> {
    if (GlobalContext.getContext().getObject('AVPlayer') === null) {
      this.avPlayer = await media.createAVPlayer();
      this.setAVPlayerCallback();
      GlobalContext.getContext().setObject('AVPlayer', this.avPlayer);
    } else {
      this.avPlayer = GlobalContext.getContext().getObject('AVPlayer') as media.AVPlayer;
    }
  }

  /**
   * 更新音乐索引值下一首音乐的索引值。
   */
  private getNext(): void {
    switch (this.musicLoopState) {
      case MusicLoopState.SINGLE:
        this.musicIndex = this.musicIndex;
        break;
      case MusicLoopState.RANDOM:
        this.musicIndex = new Date().valueOf() % CommonConstants.MUSIC.length;
        break;
      case MusicLoopState.ORDERED:
        this.musicIndex = (this.musicIndex + 1) % CommonConstants.MUSIC.length;
        break;
    }
  }

  /**
   * 更新音乐索引值上一首音乐的索引值。
   */
  private getPrev(): void {
    switch (this.musicLoopState) {
      case MusicLoopState.SINGLE:
        this.musicIndex = this.musicIndex;
        break;
      case MusicLoopState.RANDOM:
        this.musicIndex = new Date().valueOf() % CommonConstants.MUSIC.length;
        break;
      case MusicLoopState.ORDERED:
        this.musicIndex = (this.musicIndex + CommonConstants.MUSIC.length - 1) % CommonConstants.MUSIC.length;
        break;
    }
  }

  /**
   * 获取今天的日期。
   */
  private getToday(): void {
    let date: Date = new Date();
    this.today = (date.getMonth() + 1) + '月' + date.getDate() + '日' +
    CommonConstants.WEEK_DAYS[(date.getDay() + 6) % 7];
  }

  /**
   * 显示日程的结束日期。
   * @param schedule 用于计算结束时间的日程。
   * @returns 日程结束日期字符串。
   */
  private getEndTimeText(schedule: Schedule): string {
    if (schedule.endYear === 0) {
      console.error('[hxk] MyDay getEndTimeText err');
      return ''
    } else if (
      new Date(schedule.endYear + '-' + schedule.endMonth + '-' + schedule.endDate).valueOf()
      + 12 * 60 * 60 * 1000 < new Date().valueOf()
    ) {
      return schedule.endMonth + '月' + schedule.endDate + '日已过期';
    } else {
      return schedule.endMonth + '月' + schedule.endDate + '日';
    }
  }

  /**
   * 在 aboutToAppear 生命周期函数中，为 avPlayer 初始化时设置的回调函数。
   */
  private setAVPlayerCallback(): void {
    this.avPlayer.on('seekDone', (seekDoneTime) => {
      console.info(`AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
    })
    this.avPlayer.on('error', (err) => {
      console.error(`Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
      this.avPlayer.reset();
    })
    this.avPlayer.on('stateChange', async (state) => {
      switch (state) {
        case 'idle':
          console.info('AVPlayer state idle called.');
          this.playerState = 'paused';
          break;
        case 'initialized':
          console.info('AVPlayer state initialized called.');
          this.avPlayer.prepare();
          this.playerState = 'paused';
          break;
        case 'prepared':
          console.info('AVPlayer state prepared called.');
          this.playerState = 'paused';
          this.avPlayer.play();
          break;
        case 'playing':
          console.info('AVPlayer state playing called.');
          this.playerState = 'playing';
          break;
        case 'paused':
          console.info('AVPlayer state paused called.');
          this.playerState = 'paused';
          break;
        case 'completed':
          console.info('AVPlayer state completed called.');
          this.avPlayer.reset().then(async () => {
            this.getNext();
            let context = getContext(this) as common.UIAbilityContext;
            let fileDescriptor = await context.resourceManager.getRawFd(CommonConstants.MUSIC[this.musicIndex]);
            this.avPlayer.fdSrc = fileDescriptor;
          });
          break;
        case 'stopped':
          console.info('AVPlayer state stopped called.');
          this.playerState = 'paused';
          this.avPlayer.reset();
          break;
        case 'released':
          console.info('AVPlayer state released called.');
          this.playerState = 'paused';
          break;
        default:
          console.info('AVPlayer state unknown called.');
          break;
      }
    });
  }

  /**
   * 通过关系型数据库查询所有日程记录。
   */
  private getAllSchedules(): void {
    this.scheduleTable.queryData(this.currentSortRule, (results: Array<Schedule>) => {
      this.allSchedules = results;
    });
  }
}