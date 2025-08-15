import picker from '@ohos.file.picker';
import CommonConstants from '../common/constants/CommonConstants';
import PreferencesUtil from '../common/database/PreferencesUtil';
import BackgroundType from '../model/BackgroundType';
import Folder from '../model/Folder';
import FolderType from '../model/FolderType';

@CustomDialog
export default struct ChangeBackgroundDialog {
  /**
   * 对话框控制器。
   */
  public controller: CustomDialogController;

  /**
   * 当前文件夹。
   */
  @Link
  private folder: Folder;
  /**
   * 所有文件夹。
   */
  @State
  private allFolders: Array<Folder> = [];
  /**
   * 辅助轻量级数据存储管理文件夹数据的临时文件夹。
   */
  @State @Watch('updateBackground')
  private tmpFolder: Folder = {
    owner: '',
    folderName: '',
    folderType: FolderType.NORMAL,
    background: $r('app.color.default_normal_bg'),
    backgroundType: BackgroundType.COLOR
  };

  // 属性动画相关信息。
  /**
   * 选择纯色背景的 Scroll 宽度。属性动画效果。
   */
  @State
  private animationScrollStartWidth: string = '100%';
  /**
   * 选择照片背景的 Scroll 宽度。属性动画效果。
   */
  @State
  private animationScrollEndWidth: string = '0%';

  /**
   * 初始化文件夹数据。
   */
  public aboutToAppear(): void {
    this.tmpFolder.owner = this.folder.owner;
    this.tmpFolder.folderName = this.folder.folderName;
    this.tmpFolder.folderType = this.folder.folderType;
    this.tmpFolder.background = this.folder.background;

    PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
      .then((value: string) => {
        this.allFolders = JSON.parse(value) as Array<Folder>;
        console.debug('[hxk] FoldersList folders: ' + JSON.stringify(this.allFolders) + ' value: ' + value);
      });
  }

  /**
   * 更新轻量级数据存储中保存的文件夹数据。
   */
  public updateBackground(): void {
    if (this.allFolders.length > 0) {
      console.debug('[hxk] ChangeBackgroundDialog updateBackground tmpFolder: ' + JSON.stringify(this.tmpFolder));
      console.debug('[hxk] ChangeBackgroundDialog updateBackground folder: ' + JSON.stringify(this.folder));
      let index: number = this.allFolders.findIndex(
        (value: Folder): boolean =>
      value.owner === this.tmpFolder.owner
      && value.folderName === this.tmpFolder.folderName
      && value.folderType === this.tmpFolder.folderType);
      this.folder = this.tmpFolder;
      this.allFolders[index] = this.tmpFolder;
      console.debug('[hxk] ChangeBackgroundDialog allFolders: ' + JSON.stringify(this.allFolders) + ', index: ' + index);
      PreferencesUtil.savePreferences(CommonConstants.FOLDER_PREFERENCES, this.allFolders);
    }
  }

  public build(): void {
    Column() {
      Text('选择主题')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.font_black'))
        .alignSelf(ItemAlign.Start)
        .margin('2%');

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
              this.tmpFolder.background = PhotoSelectResult.photoUris[0];
              this.tmpFolder.backgroundType = BackgroundType.PHOTO;
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
                .size(this.tmpFolder.background === color ?
                  { width: 36, height: 36 } :
                  { width: 28, height: 28 })
                .onClick(() => {
                  this.tmpFolder.background = color;
                  this.tmpFolder.backgroundType = BackgroundType.COLOR;
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
                  .size(this.tmpFolder.background === color ?
                    { width: 64, height: 64 } :
                    { width: 56, height: 56 })
                  .clip(new Circle(this.tmpFolder.background === color ?
                    { width: 64, height: 64 } :
                    { width: 56, height: 56 }));
              }
              .backgroundColor(Color.Transparent)
              .type(ButtonType.Circle)
              .size(this.tmpFolder.background === color ?
                { width: 64, height: 64 } :
                { width: 56, height: 56 })
              .onClick(() => {
                this.tmpFolder.background = color;
                this.tmpFolder.backgroundType = BackgroundType.PHOTO
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
      .margin({bottom:'5%'})
      .alignItems(VerticalAlign.Center)
      .size({ width: '100%', height: '6%' });
    }
    .backgroundColor($r('app.color.main_background'))
    .size({ width: '100%' });
  }
}