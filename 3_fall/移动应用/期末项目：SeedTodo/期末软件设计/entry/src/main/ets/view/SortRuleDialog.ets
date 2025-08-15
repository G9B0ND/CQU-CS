import SortRule from '../model/SortRule';

@CustomDialog
export default struct SortRuleDialog {
  /**
   * 对话框控制器。
   */
  public controller: CustomDialogController;
  /**
   * 用户选中的排序规则。
   */
  @Link
  private currentSortRule: SortRule;

  public build(): void {
    Column() {
      List() {
        ListItem() {
          Row() {
            Image($r('app.media.home'))
              .fillColor(this.currentSortRule === SortRule.DEFAULT ? $r('app.color.blue') : $r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('默认排序')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentSortRule === SortRule.DEFAULT ? $r('app.color.blue') : $r('app.color.font_black'));
          }
          .onClick(() => {
            this.currentSortRule = SortRule.DEFAULT;
          })
          .size({ width: '100%', height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.star'))
              .fillColor(this.currentSortRule === SortRule.IMPORTANCE_DESC ? $r('app.color.blue') : $r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('重要性')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentSortRule === SortRule.IMPORTANCE_DESC ? $r('app.color.blue') : $r('app.color.font_black'));
          }
          .onClick(() => {
            this.currentSortRule = SortRule.IMPORTANCE_DESC;
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.ic_public_topping'))
              .fillColor(this.currentSortRule === SortRule.URGENCY_DESC ? $r('app.color.blue') : $r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('紧急性')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentSortRule === SortRule.URGENCY_DESC ? $r('app.color.blue') : $r('app.color.font_black'));
          }
          .onClick(() => {
            this.currentSortRule = SortRule.URGENCY_DESC;
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.sort'))
              .fillColor(this.currentSortRule === SortRule.ALPHABET_ASC ? $r('app.color.blue') : $r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('字母顺序')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentSortRule === SortRule.ALPHABET_ASC ? $r('app.color.blue') : $r('app.color.font_black'));
          }
          .onClick(() => {
            this.currentSortRule = SortRule.ALPHABET_ASC;
          })
          .size({ height: '4%' });
        }
        .margin('2%');

        ListItem() {
          Row() {
            Image($r('app.media.in_plan'))
              .fillColor(this.currentSortRule === SortRule.END_TIME_DESC ? $r('app.color.blue') : $r('app.color.font_black'))
              .size({ width: 24, height: 24 });
            Text('截止日期')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.currentSortRule === SortRule.END_TIME_DESC ? $r('app.color.blue') : $r('app.color.font_black'));
          }
          .onClick(() => {
            this.currentSortRule = SortRule.END_TIME_DESC;
          })
          .size({ height: '4%' });
        }
        .margin('2%');
      }
      .padding('2%');
    }
    .backgroundColor($r('app.color.main_background'));
  }
}