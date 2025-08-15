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
import Schedule from '../../model/Schedule';
import SortRule from '../../model/SortRule';
import Step from '../../model/Step';
import CommonConstants from '../constants/CommonConstants';
import Rdb from './Rdb';


/**
 * 日程数据表的数据存储及操作。
 */
export default class scheduleTable {
  private scheduleTable = new Rdb(
    CommonConstants.SCHEDULE_TABLE.tableName,
    CommonConstants.SCHEDULE_TABLE.sqlCreate,
    CommonConstants.SCHEDULE_TABLE.columns);

  constructor(callback: Function = () => {
  }) {
    this.scheduleTable.getRdbStore(callback);
  }

  getRdbStore(callback: Function = () => {
  }) {
    this.scheduleTable.getRdbStore(callback);
  }

  insertData(schedule: Schedule, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(schedule);
    this.scheduleTable.insertData(valueBucket, callback);
  }

  deleteData(schedule: Schedule, callback: Function) {
    let predicates = new relationalStore.RdbPredicates(CommonConstants.SCHEDULE_TABLE.tableName);
    predicates.equalTo('id', schedule.id);
    this.scheduleTable.deleteData(predicates, callback);
  }

  updateData(schedule: Schedule, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(schedule);
    let predicates = new relationalStore.RdbPredicates(CommonConstants.SCHEDULE_TABLE.tableName);
    predicates.equalTo('id', schedule.id);
    this.scheduleTable.updateData(predicates, valueBucket, callback);
  }

  queryData(sortRule: SortRule, callback: Function): void {
    let predicates = new relationalStore.RdbPredicates(CommonConstants.SCHEDULE_TABLE.tableName);
    switch (sortRule) {
      case SortRule.IMPORTANCE_ASC:
        predicates
          .orderByAsc('isImportant');
        break;
      case SortRule.IMPORTANCE_DESC:
        predicates
          .orderByDesc('isImportant');
        break;
      case SortRule.URGENCY_ASC:
        predicates
          .orderByAsc('isUrgent');
        break;
      case SortRule.URGENCY_DESC:
        predicates
          .orderByDesc('isUrgent');
        break;
      case SortRule.END_TIME_ASC:
        predicates
          .orderByAsc('endYear')
          .orderByAsc('endMonth')
          .orderByAsc('endDate');
        break;
      case SortRule.END_TIME_DESC:
        predicates
          .orderByDesc('endYear')
          .orderByDesc('endMonth')
          .orderByDesc('endDate');
        break;
      case SortRule.ALPHABET_ASC:
        predicates
          .orderByAsc('scheduleName');
        break;
      case SortRule.IMPORTANCE_ASC:
        predicates
          .orderByDesc('scheduleName');
        break;
      default:
        break;
    }

    this.scheduleTable.query(predicates, (resultSet: relationalStore.ResultSet) => {
      let count: number = resultSet.rowCount;
      console.debug('[hxk] count: ' + count.toString());
      if (count === 0 || typeof count === 'string') {
        callback([]);
      } else {
        resultSet.goToFirstRow();
        const result: Array<Schedule> = [];
        for (let i = 0; i < count; i++) {
          result[i] = {
            id: resultSet.getDouble(resultSet.getColumnIndex('id')),
            username: resultSet.getString(resultSet.getColumnIndex('username')),
            folderName: resultSet.getString(resultSet.getColumnIndex('folderName')),
            scheduleName: resultSet.getString(resultSet.getColumnIndex('scheduleName')),
            steps: JSON.parse(resultSet.getString(resultSet.getColumnIndex('steps'))) as Array<Step>,
            endYear: resultSet.getDouble(resultSet.getColumnIndex('endYear')),
            endMonth: resultSet.getDouble(resultSet.getColumnIndex('endMonth')),
            endDate: resultSet.getDouble(resultSet.getColumnIndex('endDate')),
            remindTime: resultSet.getString(resultSet.getColumnIndex('remindTime')),
            isAlarmRemind: resultSet.getDouble(resultSet.getColumnIndex('isAlarmRemind')) === 1 ? true : false,
            reminderId: resultSet.getDouble(resultSet.getColumnIndex('reminderId')),
            repeatInterval: JSON.parse(resultSet.getString(resultSet.getColumnIndex('repeatInterval'))) as Array<boolean>,
            description: resultSet.getString(resultSet.getColumnIndex('description')),
            isMyDay: resultSet.getDouble(resultSet.getColumnIndex('isMyDay')) === 1 ? true : false,
            isImportant: resultSet.getDouble(resultSet.getColumnIndex('isImportant')) === 1 ? true : false,
            isUrgent: resultSet.getDouble(resultSet.getColumnIndex('isUrgent')) === 1 ? true : false,
            isFinished: resultSet.getDouble(resultSet.getColumnIndex('isFinished')) === 1 ? true : false
          };
          resultSet.goToNextRow();
        }
        callback(result);
      }
    });
  }
}

function generateBucket(schedule: Schedule): relationalStore.ValuesBucket {
  return {
    username: schedule.username,
    folderName: schedule.folderName,
    scheduleName: schedule.scheduleName,
    steps: JSON.stringify(schedule.steps),
    endYear: schedule.endYear,
    endMonth: schedule.endMonth,
    endDate: schedule.endDate,
    remindTime: schedule.remindTime,
    isAlarmRemind: schedule.isAlarmRemind ? 1 : 0,
    reminderId: schedule.reminderId,
    repeatInterval: JSON.stringify(schedule.repeatInterval),
    description: schedule.description,
    isMyDay: schedule.isMyDay ? 1 : 0,
    isImportant: schedule.isImportant ? 1 : 0,
    isUrgent: schedule.isUrgent ? 1 : 0,
    isFinished: schedule.isFinished ? 1 : 0
  };
}