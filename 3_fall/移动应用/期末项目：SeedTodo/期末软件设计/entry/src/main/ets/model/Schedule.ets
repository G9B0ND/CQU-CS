import Step from './Step';

/**
 * 日程数据类型。
 */
export default interface Schedule {
  id: number;
  username: string;
  folderName: string;
  scheduleName: string;
  steps: Array<Step>;
  endYear: number;
  endMonth: number;
  endDate: number;
  remindTime: string;
  isAlarmRemind: boolean;
  reminderId: number;
  repeatInterval: Array<boolean>;
  description: string;
  isMyDay: boolean;
  isImportant: boolean;
  isUrgent: boolean;
  isFinished: boolean;
}