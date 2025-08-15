import router from '@ohos.router';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import CommonConstants from '../common/constants/CommonConstants';
import scheduleTable from '../common/database/ScheduleTable';
import ArrayUtil from '../common/util/ArrayUtil';
import BackgroundType from '../model/BackgroundType';
import Folder from '../model/Folder';
import FolderType from '../model/FolderType';
import Schedule from '../model/Schedule'
import Step from '../model/Step';
import RepeatIntervalDialog from '../view/RepeatIntervalDialog';
import notificationManager from '@ohos.notificationManager';
import reminderAgentManager from '@ohos.reminderAgentManager';
import PreferencesUtil from '../common/database/PreferencesUtil';

/**
 * 日程编辑页面。
 */
@Entry
@Component
struct EditSchedule {
  // 数据存储相关信息。
  /**
   * 页面跳转的来源文件夹。
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
   * 所有文件夹。包括其他用户数据。
   */
  @State @Watch('getFolders')
  private allFolders: Array<Folder> = [];
  /**
   * 当前用户的所有文件夹。
   */
  @State
  private folders: Array<Folder> = [];

  // 日程步骤相关信息。
  /**
   * 日程步骤。
   */
  @State @Watch('updateSteps')
  private steps: Array<Step> = [];
  /**
   * 新步骤名称。
   */
  @State
  private newStepName: string = '';
  /**
   * 正在编辑的日程步骤信息。
   */
  @State
  private editingStep: Step = null!;

  /**
   * 表示是否跳转自搜索页面。
   */
  @State
  private isSearch: boolean = false;

  /**
   * 控制圆圈图标属性动画。
   */
  @State
  private animationCircleSize: number = 24;

  /**
   * 提醒时间按钮文字。
   */
  @State
  private remindButtonText: string = '提醒我';
  /**
   * 重复周期按钮文字。
   */
  @State
  private repeatButtonText: string = '重复';
  /**
   * 重复周期。
   */
  @State @Watch('updateRepeatInterval')
  private repeatInterval: Array<boolean> =
    [false, false, false, false, false, false, false];

  /**
   * 当前时间。
   */
  private currentTime: Date = new Date();

  /**
   * 提醒时间。
   */
  private remindTime: Date = new Date();

  /**
   * 被编辑的日程。
   */
  @State @Watch('getRepeatButtonText')
  private schedule: Schedule = {
    id: -1,
    username: '',
    folderName: '',
    scheduleName: '',
    steps: [],
    endYear: 0,
    endDate: 0,
    endMonth: 0,
    remindTime: '',
    isAlarmRemind: false,
    reminderId: -1,
    repeatInterval: [false, false, false, false, false, false, false],
    description: '',
    isMyDay: false,
    isImportant: false,
    isUrgent: false,
    isFinished: false
  };

  /**
   * 关系型数据库管理。
   */
  private scheduleTable: scheduleTable = new scheduleTable();

  /**
   * 重复周期对话框。
   */
  private repeatIntervalDialogController: CustomDialogController = new CustomDialogController({
    autoCancel: false,
    builder: RepeatIntervalDialog({ repeatInterval: $repeatInterval }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  /**
   * 初始化被编辑的日程、文件夹、日程记录、各按钮显示的文字等数据。
   */
  public aboutToAppear(): void {
    if (Object(router.getParams())?.['schedule']) {
      this.schedule = Object(router.getParams())['schedule'];
    }
    if (Object(router.getParams())?.['folder']) {
      this.folder = Object(router.getParams())['folder'];
    } else {
      this.isSearch = true;
    }
    this.scheduleTable.getRdbStore();
    this.steps = this.schedule.steps;
    this.getRepeatButtonText();
    this.getRemindButtonText();
    this.getEndDateString()

    PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
      .then((value: string) => {
        this.allFolders = JSON.parse(value) as Array<Folder>;
        console.debug('[hxk] FoldersList folders: ' + JSON.stringify(this.allFolders) + ' value: ' + value);
      });
  }

  /**
   * 当 repeatInterval 改变时触发。
   * 更新重复周期并更新日程。
   */
  public updateRepeatInterval(): void {
    this.schedule.repeatInterval = this.repeatInterval;
    this.scheduleTable.updateData(this.schedule, () => {
    });
  }

  /**
   * 当 allFolders 改变时触发。
   * 获取当前用户拥有的所有文件夹。
   */
  public getFolders(): void {
    this.folders = ArrayUtil.subArray(this.allFolders,
      (value: Folder): boolean => value.owner === this.folder.owner && value.folderType === FolderType.NORMAL);
  }

  /**
   * 当 steps 改变时触发。
   * 更新日程步骤。
   */
  public updateSteps(): void {
    this.schedule.steps = this.steps;
  }

  public build(): void {
    Column() {
      Row({ space: 8 }) {
        Button() {
          Image($r('app.media.ic_public_back'))
            .size({ width: 28, height: 28 })
            .fillColor($r('app.color.font_black'));
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          if (this.isSearch) {
            router.replaceUrl({
              url: 'pages/SearchSchedule',
              params: {
                username: this.schedule.username
              }
            })
          } else {
            if (this.schedule.id === -1) {
              this.scheduleTable.insertData(this.schedule, () => {
              });
            }
            router.replaceUrl({
              url: 'pages/MyDay',
              params: {
                folder: this.folder
              }
            });
          }
        });
        Text(this.folder.folderName)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.font_black'));
        Blank();
      }
      .size({ width: '96%', height: '4%' })
      .margin({ top: '10%', left: '2%', right: '2%' });

      List() {
        ListItem() {
          Row({ space: 8 }) {
            Button() {
              Image(this.schedule.isFinished
                ? $r('app.media.circle_filled')
                : $r('app.media.circle'))
                .size({ width: this.animationCircleSize, height: this.animationCircleSize })
                .fillColor($r('app.color.font_black'))
                .margin('2%');
            }
            .backgroundColor(Color.Transparent)
            .size({ width: 28, height: 28 })
            .onClick(() => {
              this.schedule.isFinished = !this.schedule.isFinished;
              animateTo({ duration: 200, curve: Curve.Rhythm },
                () => this.animationCircleSize = 0);
              animateTo({ duration: 200, curve: Curve.Rhythm, delay: 200 },
                () => this.animationCircleSize = 28);
            });

            TextInput({ text: this.schedule.scheduleName })
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.font_black'))
              .size({ width: '56%' })
              .onChange((value: string) => {
                this.schedule.scheduleName = value;
                if (value.length === 0) {
                  this.schedule.scheduleName = '（无标题）';
                }
                this.scheduleTable.updateData(this.schedule, () => {
                });
              });

            Blank();

            Button() {
              Row() {
                Text('紧急')
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.font_grey'));
                Image(this.schedule.isUrgent
                  ? $r('app.media.ic_public_topping_filled')
                  : $r('app.media.ic_public_topping'))
                  .size({ width: 24, height: 24 })
                  .fillColor(this.schedule.isUrgent
                    ? $r('app.color.red')
                    : $r('app.color.font_grey'));
              };
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.schedule.isUrgent = !this.schedule.isUrgent;
              this.scheduleTable.updateData(this.schedule, () => {
              });
            });

            Divider()
              .vertical(true)
              .color($r('app.color.font_grey'))
              .height('64%');

            Button() {
              Row() {
                Text('重要')
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.font_grey'));
                Image(this.schedule.isImportant
                  ? $r('app.media.star_filled')
                  : $r('app.media.star'))
                  .size({ width: 24, height: 24 })
                  .fillColor(this.schedule.isImportant
                    ? $r('app.color.blue')
                    : $r('app.color.font_grey'));
              };
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.schedule.isImportant = !this.schedule.isImportant;
              this.scheduleTable.updateData(this.schedule, () => {
              });
            });
          }
          .size({ width: '96%', height: '6%' })
          .margin('2%');
        };

        ListItemGroup() {
          ForEach(this.steps, (step: Step, index: number) => {
            ListItem() {
              Row({ space: 8 }) {
                Image(step.isFinished
                  ? $r('app.media.circle_filled') : $r('app.media.circle'))
                  .size({ width: 24, height: 24 })
                  .fillColor(step.isFinished
                    ? $r('app.color.blue') : $r('app.color.font_black'))
                  .onClick(() => {
                    this.steps[index].isFinished = !this.steps[index].isFinished;
                    this.scheduleTable.updateData(this.schedule, () => {
                    });
                    this.refreshSteps();
                  });
                if (this.editingStep !== null && this.editingStep.stepName === step.stepName) {
                  TextInput({ text: step.stepName })
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .size({ width: '84%' })
                    .onChange((value: string) => {
                      if (value.length > 0) {
                        this.steps[index].stepName = value;
                      } else {
                        this.steps.splice(index, 1);
                      }
                      this.scheduleTable.updateData(this.schedule, () => {
                      });
                    })
                    .onSubmit(() => {
                      this.editingStep = null!;
                      this.refreshSteps();
                    });
                } else {
                  Text(step.stepName)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(step.isFinished
                      ? $r('app.color.font_grey') : $r('app.color.font_black'))
                    .size({ width: '84%' })
                    .maxLines(1)
                    .decoration(step.isFinished
                      ? {
                          type: TextDecorationType.LineThrough,
                          color: $r('app.color.font_grey')
                        }
                      : {
                          type: TextDecorationType.None,
                        })
                    .onClick(() => {
                      this.editingStep = step;
                      console.debug('[hxk] EditSchedule editingStep: ' + JSON.stringify(this.editingStep));
                      this.refreshSteps();
                    });
                }
                Image($r('app.media.dot_list'))
                  .size({ width: 24, height: 24 })
                  .fillColor($r('app.color.font_grey'))
                  .bindMenu(this.StepMenu(step, index));
              }
              .size({ width: '88%', height: '6%' });
            }
          }, (step: Step, index: number) => index + JSON.stringify(step));
          ListItem() {
            Row({ space: 8 }) {
              Image($r('app.media.ic_public_add_black'))
                .size({ width: 24, height: 24 })
                .fillColor($r('app.color.blue'));
              TextInput({ placeholder: this.schedule.steps.length > 0
                ? '下一步' : '添加步骤', text: this.newStepName })
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .size({ width: '84%' })
                .onChange((value: string) => {
                  this.newStepName = value;
                });
              Image($r('app.media.ic_public_ok_black'))
                .size({ width: 24, height: 24 })
                .fillColor(this.newStepName.length === 0
                  ? $r('app.color.font_grey') : $r('app.color.blue'))
                .onClick(() => {
                  if (this.newStepName.length > 0) {
                    this.steps.push({ stepName: this.newStepName, isFinished: false });
                    this.scheduleTable.updateData(this.schedule, () => {
                    });
                    this.newStepName = '';
                  }
                });
            }
            .size({ width: '88%', height: '6%' });
          };
        };

        ListItem() {
          Divider()
            .color($r('app.color.font_grey'))
            .margin('2%');
        };

        ListItemGroup() {
          ListItem() {
            Row({ space: 8 }) {
              Image($r('app.media.my_day'))
                .size({ width: 24, height: 24 })
                .fillColor(this.schedule.isMyDay
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
              Text('添加到“今日代办”')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.schedule.isMyDay
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
            }
            .size({ width: '96%', height: '6%' })
            .onClick(() => {
              this.schedule.isMyDay = !this.schedule.isMyDay;
              this.scheduleTable.updateData(this.schedule, () => {
              });
            });
          };

          ListItem() {
            Row() {
              Image($r('app.media.ring'))
                .size({ width: 24, height: 24 })
                .fillColor(this.schedule.remindTime.length > 0
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
              Text(this.remindButtonText)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.schedule.remindTime.length > 0
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
              Blank();
              if (this.schedule.remindTime.length > 0) {
                Button() {
                  Row() {
                    Text('闹钟提醒')
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.schedule.isAlarmRemind
                        ? $r('app.color.blue')
                        : $r('app.color.font_grey'));
                    Toggle({ type: ToggleType.Switch, isOn: this.schedule.isAlarmRemind })
                      .size({ width: 24, height: 24 })
                      .onChange((isOn: boolean) => {
                        this.schedule.isAlarmRemind = isOn;
                        this.scheduleTable.updateData(this.schedule, () => {
                        });
                      });
                  };
                }
                .backgroundColor(Color.Transparent)
                .onClick(() => {
                  this.schedule.isAlarmRemind = !this.schedule.isAlarmRemind;
                  this.scheduleTable.updateData(this.schedule, () => {
                  });
                });
              }
            }
            .size({ width: '96%', height: '6%' })
            .onClick(() => {
              abilityAccessCtrl.createAtManager()
                .requestPermissionsFromUser(getContext(),
                  ['ohos.permission.PUBLISH_AGENT_REMINDER']);
            })
            .bindMenu(this.RemindTimeMenu());
          };

          ListItem() {
            Row() {
              Image($r('app.media.in_plan'))
                .size({ width: 24, height: 24 })
                .fillColor(this.schedule.endYear > 0
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
              Text(this.schedule.endYear === 0
                ? '截止日期'
                : this.getEndDateString())
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.schedule.endYear > 0
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
            }
            .size({ width: '96%', height: '6%' })
            .onClick(() => {
              DatePickerDialog.show({
                start: new Date(),
                end: new Date('2030-12-31'),
                lunar: false,
                onAccept: (value: DatePickerResult) => {
                  this.schedule.endYear = value.year;
                  this.schedule.endMonth = value.month! + 1;
                  this.schedule.endDate = value.day;
                  this.scheduleTable.updateData(this.schedule, () => {
                  });
                }
              });
            });
          };

          ListItem() {
            Row() {
              Image($r('app.media.repeat'))
                .size({ width: 24, height: 24 })
                .fillColor(!ArrayUtil.equalTo(this.schedule.repeatInterval,
                  [false, false, false, false, false, false, false])
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
              Text(this.repeatButtonText)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(!ArrayUtil.equalTo(this.schedule.repeatInterval,
                  [false, false, false, false, false, false, false])
                  ? $r('app.color.blue')
                  : $r('app.color.font_grey'));
              Blank();
              if (!ArrayUtil.equalTo(this.schedule.repeatInterval,
                [false, false, false, false, false, false, false])) {
                Image($r('app.media.cancel'))
                  .size({ width: 24, height: 24 })
                  .fillColor($r('app.color.red'))
                  .onClick(() => {
                    this.repeatInterval = [false, false, false, false, false, false, false];
                  });
              }
            }
            .size({ width: '96%', height: '6%' })
            .bindMenu(this.RepeatIntervalMenu());
          };
        };

        ListItem() {
          Divider()
            .color($r('app.color.font_grey'))
            .margin({top:'2%',bottom:'5%'});
        };

        ListItem() {
          TextArea({ placeholder: '添加备注' })
            .fontSize(16)
            .fontWeight(FontWeight.Normal)
            .fontColor($r('app.color.font_grey'))
            .size({ width: '96%', height: '32%' })
            .padding('2%')
            .onChange((value: string) => {
              this.schedule.description = value;
              this.scheduleTable.updateData(this.schedule, () => {
              });
            });
        };
      }
      .alignListItem(ListItemAlign.Center);
      Blank();
      Divider()
        .color($r('app.color.font_grey'))
        .margin('2%');
      Row() {
        Image($r('app.media.dustbin'))
          .size({ width: 24, height: 24 })
          .fillColor($r('app.color.red'))
          .margin({right:'5%'})
          .onClick(() => {
            AlertDialog.show({
              message: '确定要删除该日程吗？',
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
                  if (this.schedule.reminderId > 0) {
                    reminderAgentManager.cancelReminder(this.schedule.reminderId);
                  }
                  this.scheduleTable.deleteData(this.schedule, () => {
                  });
                }
              }
            })
          });
      }
      .justifyContent(FlexAlign.End)
      .size({ width: '96%', height: '4%' })
      .margin({bottom:'20%'});
    }
    .size({ width: '100%', height: '100%' })
    .backgroundImage($r('app.media.backgroundedit'))
    .backgroundImageSize({ width: '100%', height: '100%' });
  }

  /**
   * 更改提醒时间相关组件绑定的菜单栏。
   */
  @Builder
  private RemindTimeMenu(): void {
    List() {
      ListItem() {
        Row() {
          Image($r('app.media.remind_today'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('今日晚些时候' +
          (CommonConstants.DEFAULT_REMIND_TIME.find(
            (value: number) => this.currentTime.getHours() < value) !== undefined
            ? ('（' + ((CommonConstants.DEFAULT_REMIND_TIME.find(
              (value: number) => this.currentTime.getHours() < value) ?? 0) < 10 ? '0' : '') +
            CommonConstants.DEFAULT_REMIND_TIME.find(
              (value: number) => this.currentTime.getHours() < value) + ':00）')
            : ''))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(CommonConstants.DEFAULT_REMIND_TIME.find(
              (value: number) => this.currentTime.getHours() < value) !== undefined
              ? $r('app.color.font_black') : $r('app.color.font_grey'))
            .enabled(CommonConstants.DEFAULT_REMIND_TIME.find(
              (value: number) => this.currentTime.getHours() < value) !== undefined)
            .onClick(() => {
              this.currentTime = new Date();
              let remindToday = CommonConstants.DEFAULT_REMIND_TIME.find(
                (value: number) => this.currentTime.getHours() < value);
              this.remindTime.setHours(remindToday!, 0, 0, 0);
              this.schedule.remindTime = JSON.stringify(this.remindTime);
              this.setReminder();
              this.getRemindButtonText();
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.remind_tomorrow'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('明天（' + CommonConstants.WEEK_DAYS[this.currentTime.getDay()] + ') 09:00')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.currentTime = new Date();
              this.remindTime.setDate(this.currentTime.getDate() + 1);
              this.remindTime.setHours(9, 0, 0, 0);
              this.schedule.remindTime = JSON.stringify(this.remindTime);
              this.setReminder();
              this.getRemindButtonText();
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.pick_date'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('选择日期和时间')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.currentTime = new Date();
              DatePickerDialog.show({
                start: this.currentTime,
                end: new Date('2030-12-31'),
                lunar: false,
                onAccept: (value: DatePickerResult) => {
                  this.remindTime.setFullYear(value.year);
                  this.remindTime.setMonth(value.month);
                  this.remindTime.setDate(value.day);
                  TimePickerDialog.show({
                    useMilitaryTime: true,
                    selected: this.schedule.remindTime.length === 0
                      ? new Date(this.currentTime.valueOf() + 1000 * 60 * 60)
                      : this.remindTime,
                    onAccept: (value: TimePickerResult) => {
                      this.remindTime.setHours(value.hour, value.minute, 0, 0);
                      this.schedule.remindTime = JSON.stringify(this.remindTime);
                      this.setReminder();
                      this.getRemindButtonText();
                    }
                  });
                }
              });
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      if (this.schedule.remindTime.length > 0) {
        ListItem() {
          Row() {
            Image($r('app.media.ic_public_delete_red'))
              .fillColor($r('app.color.red'))
              .size({ width: 24, height: 24 });
            Text('清除提醒时间')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'))
              .onClick(() => {
                this.schedule.remindTime = '';
                this.remindTime = this.currentTime;
                this.setReminder();
                this.getRemindButtonText();
                this.scheduleTable.updateData(this.schedule, () => {
                });
              });
          }
          .size({ height: '4%' });
        }
        .margin('2%');
      }
    }
    .padding('2%')
    .size({ width: '84%' });
  }

  /**
   * 更改重复周期相关组件绑定的菜单栏。
   */
  @Builder
  private RepeatIntervalMenu(): void {
    List() {
      ListItem() {
        Row() {
          Image($r('app.media.repeat_daily'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('每天')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatInterval = [true, true, true, true, true, true, true];
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.repeat_weekdays'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('工作日')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatInterval = [true, true, true, true, true, false, false];
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.repeat_weekends'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('周末')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatInterval = [false, false, false, false, false, true, true];
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.repeat_weekly'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('每周' + CommonConstants.WEEK_DAYS[(this.currentTime.getDay() + 6) % 7])
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatInterval = [
                0 === (this.currentTime.getDay() + 6) % 7,
                1 === (this.currentTime.getDay() + 6) % 7,
                2 === (this.currentTime.getDay() + 6) % 7,
                3 === (this.currentTime.getDay() + 6) % 7,
                4 === (this.currentTime.getDay() + 6) % 7,
                5 === (this.currentTime.getDay() + 6) % 7,
                6 === (this.currentTime.getDay() + 6) % 7,
              ];
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.pick_date'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('自定义')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatIntervalDialogController.open();
              this.getRepeatButtonText();
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');
    }
    .padding('2%')
    .size({ width: '84%' });
  }

  /**
   * 更改日程文件夹相关组件绑定的菜单栏。
   */
  @Builder
  private FoldersMenu(): void {
    List() {
      if (this.schedule.folderName.length > 0) {
        ListItem() {
          Row() {
            Text('全部日程')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'))
              .onClick(() => {
                this.schedule.folderName = '';
                this.scheduleTable.updateData(this.schedule, () => {
                });
              });
          }
          .size({ height: '4%' });
        }
        .margin('2%');
      }

      ForEach(this.folders, (folder: Folder) => {
        ListItem() {
          Row() {
            Text(folder.folderName)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(folder.folderName === this.schedule.folderName
                ? $r('app.color.blue') : $r('app.color.font_black'))
              .onClick(() => {
                this.schedule.folderName = folder.folderName;
                this.scheduleTable.updateData(this.schedule, () => {
                });
              });
          }
          .size({ height: '4%' });
        }
        .margin('2%');
      }, (folder: Folder) => JSON.stringify(folder));
    }
    .padding('2%');
  }

  /**
   * 步骤组件右侧按钮绑定的菜单栏。
   */
  @Builder
  private StepMenu(step: Step, index: number): void {
    List() {
      ListItem() {
        Row() {
          Image($r('app.media.ic_public_add_black'))
            .size({ width: 24, height: 24 })
            .fillColor($r('app.color.font_black'));
          Text('提升为日程')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'));
        }
        .size({ height: '4%' })
        .onClick(() => {
          this.steps.splice(index, 1);
          this.scheduleTable.updateData(this.schedule, () => {
          });
          this.scheduleTable.insertData({
            id: -1,
            username: this.schedule.username,
            folderName: this.schedule.folderName,
            scheduleName: step.stepName,
            steps: [],
            endYear: 0,
            endMonth: 0,
            endDate: 0,
            remindTime: '',
            isAlarmRemind: false,
            reminderId: -1,
            repeatInterval: [false, false, false, false, false, false, false],
            description: '',
            isMyDay: this.schedule.isMyDay,
            isImportant: false,
            isUrgent: false,
            isFinished: false
          }, () => {
          });
        });
      }
      .margin({ top: '2%', bottom: '2%' });

      ListItem() {
        Row() {
          Image($r('app.media.delete'))
            .size({ width: 24, height: 24 })
            .fillColor($r('app.color.font_black'));
          Text('删除步骤')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'));
        }
        .size({ height: '4%' })
        .onClick(() => {
          this.steps.splice(index, 1);
          this.scheduleTable.updateData(this.schedule, () => {
          });
        });
      }
      .margin({ top: '2%', bottom: '2%' });
    }
    .padding('2%')
    .size({ width: '84%' });
  }

  /**
   * 刷新日程步骤相关组件。
   */
  private refreshSteps(): void {
    let tmp: Array<Step> = this.steps;
    this.steps = [];
    this.steps = tmp;
  }

  /**
   * 获取重复周期字符串。
   */
  private getRepeatButtonText(): void {
    if (ArrayUtil.equalTo(this.schedule.repeatInterval, [false, false, false, false, false, false, false])) {
      this.repeatButtonText = '重复';
    } else if (ArrayUtil.equalTo(this.schedule.repeatInterval, [true, true, true, true, true, true, true])) {
      this.repeatButtonText = '每天';
    } else if (ArrayUtil.equalTo(this.schedule.repeatInterval, [true, true, true, true, true, false, false])) {
      this.repeatButtonText = '工作日';
    } else if (ArrayUtil.equalTo(this.schedule.repeatInterval, [false, false, false, false, false, true, true])) {
      this.repeatButtonText = '周末';
    } else {
      let repeatButtonText = '每周:';
      this.repeatInterval.forEach((value: boolean, index: number) => {
        if (value) {
          repeatButtonText = repeatButtonText + CommonConstants.WEEK_DAYS[index] + ',';
        }
      });
      if (repeatButtonText[repeatButtonText.length - 1] === ',') {
        this.repeatButtonText = repeatButtonText.slice(0, repeatButtonText.length - 1);
      }
    }
  }


  /**
   * 获取提醒时间字符串。
   */
  private getRemindButtonText(): void {
    if (this.schedule.remindTime.length === 0) {
      this.remindButtonText = '提醒我';
    } else if (this.remindTime.getDate() === this.currentTime.getDate()) {
      this.remindButtonText = '在今日' +
      (this.remindTime.getHours() < 10 ? '0' : '') + this.remindTime.getHours() +
      ':' + (this.remindTime.getMinutes() < 10 ? '0' : '') + this.remindTime.getMinutes() +
      '时提醒我';
    } else if (this.remindTime.getDate() === this.currentTime.getDate() + 1) {
      this.remindButtonText = '在明日' +
      (this.remindTime.getHours() < 10 ? '0' : '') + this.remindTime.getHours() +
      ':' + (this.remindTime.getMinutes() < 10 ? '0' : '') + this.remindTime.getMinutes() +
      '时提醒我';
    } else if (this.remindTime.getFullYear() === this.currentTime.getFullYear()) {
      this.remindButtonText = '在' +
      (this.remindTime.getMonth() + 1) + '月' +
      this.remindTime.getDate() + '日' +
      (this.remindTime.getHours() < 10 ? '0' : '') + this.remindTime.getHours() +
      ':' + (this.remindTime.getMinutes() < 10 ? '0' : '') + this.remindTime.getMinutes() +
      '时提醒我';
    } else {
      this.remindButtonText = '在' +
      this.remindTime.getFullYear() + '年' +
      (this.remindTime.getMonth() + 1) + '月' +
      this.remindTime.getDate() + '日' +
      (this.remindTime.getHours() < 10 ? '0' : '') + this.remindTime.getHours() +
      ':' + (this.remindTime.getMinutes() < 10 ? '0' : '') + this.remindTime.getMinutes() +
      '时提醒我';
    }
  }


  /**
   * 获取结束日期字符串。
   */
  private getEndDateString(): string {
    if (this.schedule.endYear === this.currentTime.getFullYear()
    && this.schedule.endMonth === this.currentTime.getMonth() + 1
    && this.schedule.endDate === this.currentTime.getDate()) {
      return '今日到期';
    } else if (this.schedule.endYear === this.currentTime.getFullYear()
    && this.schedule.endMonth === this.currentTime.getMonth() + 1
    && this.schedule.endDate === this.currentTime.getDate() + 1) {
      return '明日到期';
    } else {
      return this.schedule.endMonth + '月' + this.schedule.endDate + '日到期';
    }
  }


  /**
   * 设置提醒。
   */
  private setReminder(): void {
    if (this.schedule.reminderId > 0 && this.schedule.remindTime.length === 0) {
      reminderAgentManager.cancelReminder(this.schedule.reminderId);
      this.schedule.reminderId = -1;
      this.scheduleTable.updateData(this.schedule, () => {
      });
    } else if (this.schedule.remindTime.length > 0) {
      let reminder: reminderAgentManager.ReminderRequestCalendar | reminderAgentManager.ReminderRequestAlarm;
      if (this.schedule.isAlarmRemind) {
        reminder = {
          reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
          hour: this.remindTime.getHours(),
          minute: this.remindTime.getMinutes(),
          daysOfWeek: [],
          actionButton: [
            {
              title: '关闭',
              type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
            },
            {
              title: "稍后提醒",
              type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
            }
          ],
          wantAgent: {
            pkgName: 'com.my_calendar',
            abilityName: 'com.my_calendar.EntryAbility'
          },
          maxScreenWantAgent: {
            pkgName: 'com.my_calendar',
            abilityName: 'com.my_calendar.EntryAbility'
          },
          ringDuration: 20,
          snoozeTimes: 2,
          timeInterval: 5,
          title: '今日日程:' + this.schedule.scheduleName,
          content: this.schedule.description,
          expiredContent: '提醒已过期',
          snoozeContent: '稍后提醒',
          slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        };
      } else {
        reminder = {
          reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
          dateTime: {
            year: this.remindTime.getFullYear(),
            month: this.remindTime.getMonth() + 1,
            day: this.remindTime.getDate(),
            hour: this.remindTime.getHours(),
            minute: this.remindTime.getMinutes(),
            second: this.remindTime.getSeconds()
          },
          repeatMonths: [],
          repeatDays: [],
          actionButton: [
            {
              title: '关闭',
              type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
            },
            {
              title: "稍后提醒",
              type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
            }
          ],
          wantAgent: {
            pkgName: 'com.my_calendar',
            abilityName: 'com.my_calendar.EntryAbility'
          },
          maxScreenWantAgent: {
            pkgName: 'com.my_calendar',
            abilityName: 'com.my_calendar.EntryAbility'
          },
          ringDuration: 20,
          snoozeTimes: 2,
          timeInterval: 5,
          title: '今日日程:' + this.schedule.scheduleName,
          content: this.schedule.description,
          expiredContent: '提醒已过期',
          snoozeContent: '稍后提醒',
          slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION
        };
      }
      if (this.schedule.reminderId > 0) {
        reminder.notificationId = this.schedule.reminderId;
      }
      reminderAgentManager.publishReminder(reminder, (_, reminderId: number) => {
        this.schedule.reminderId = reminderId;
        this.scheduleTable.updateData(this.schedule, () => {
        });
      });
    }
  }
}