/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import relationalStore from '@ohos.data.relationalStore';
import Table from '../../model/Table';

/**
 * 应用中使用的各种常量。
 */
export default class CommonConstants {
  /**
   * 关系型数据库设置。
   */
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'database.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };
  /**
   * Schedule 数据表设置。
   */
  static readonly SCHEDULE_TABLE: Table = {
    tableName: 'scheduleTable',
    sqlCreate: 'CREATE TABLE IF NOT EXISTS scheduleTable(' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'username TEXT, folderName TEXT, scheduleName TEXT, ' +
    'steps TEXT, endYear INTEGER, endMonth INTEGER, endDate INTEGER, ' +
    'remindTime TEXT, isAlarmRemind INTEGER, reminderId INTEGER, repeatInterval TEXT, description TEXT, ' +
    'isMyDay INTEGER, isImportant INTEGER, isUrgent INTEGER, isFinished INTEGER);',
    columns: ['id', 'username', 'folderName', 'scheduleName',
      'steps', 'endYear', 'endMonth', 'endDate', 'remindTime', 'isAlarmRemind',
      'reminderId', 'repeatInterval', 'description',
      'isMyDay', 'isImportant', 'isUrgent', 'isFinished']
  };

  /**
   * 全局的获取首选项函数。
   */
  static readonly GET_PREFERENCES: string = 'getPreferences';

  /**
   * 轻量级数据存储首选项名称。
   */
  static readonly PREFERENCES_NAME: string = 'myPreferences';

  /**
   * 轻量级数据存储：账户。
   */
  static readonly ACCOUNT_PREFERENCES: string = 'accountPreferences';

  /**
   * 轻量级数据存储：文件夹。
   */
  static readonly FOLDER_PREFERENCES: string = 'folderPreferences';

  /**
   * 轻量级数据存储：自动登录。
   */
  static readonly LOGIN_PREFERENCES: string = 'loginPreferences';

  /**
   * 星期字符串。
   */
  static readonly WEEK_DAYS: Array<string> = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];

  /**
   * 纯色背景。
   */
  static readonly COLORS: Array<Resource> = [$r('app.color.FFFFFF'), $r('app.color.33539E'), $r('app.color.7FACD6'), $r('app.color.BFB8DA'), $r('app.color.E8B7D4'), $r('app.color.A5678E')];

  /**
   * 图片背景。
   */
  static readonly PHOTOS: Array<Resource> = [
  $rawfile('background/1.png'),
  $rawfile('background/2.jpg'),
  $rawfile('background/3.jpg'),
  $rawfile('background/4.jpg'),
  $rawfile('background/5.jpg'),
  $rawfile('background/6.jpg'),
  $rawfile('background/7.jpg'),
  $rawfile('background/8.jpg'),
  $rawfile('background/9.jpg')
  ]

  /**
   * 提醒时间（“今日晚些时候”）候选时间（小时）。
   */
  static readonly DEFAULT_REMIND_TIME: Array<number> = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];

  /**
   * 音乐列表
   */
  static readonly MUSIC: Array<string> = [
    'music/01.mp3',
    'music/02.mp3',
    'music/03.mp3',
    'music/04.mp3'
  ];
}