/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import dataPreferences from '@ohos.data.preferences';
import Account from '../../model/Account';
import Folder from '../../model/Folder';
import CommonConstants from '../constants/CommonConstants';
import GlobalContext from '../util/GlobalContext';

/**
 * The PreferencesUtil provides preferences of create, save and query.
 */
class PreferencesUtil {
  public createBudgets(context: Context): void {
    let getPreferences: Function = (() => {
      let preferences: Promise<dataPreferences.Preferences> =
      dataPreferences.getPreferences(context, CommonConstants.PREFERENCES_NAME);
      return preferences;
    });
    GlobalContext.getContext().setObject(CommonConstants.GET_PREFERENCES, getPreferences);
  }

  public saveDefaultPreferences(preferencesName: string, value: Array<Account> | Array<Folder>): void {
    let getPreferences: Function =
      GlobalContext.getContext().getObject(CommonConstants.GET_PREFERENCES) as Function;
    getPreferences().then((preferences: dataPreferences.Preferences) => {
      preferences.has(preferencesName).then(async (isExist: boolean) => {
        if (!isExist) {
          await preferences.put(preferencesName, JSON.stringify(value));
          preferences.flush();
        }
      }).catch((err: Error) => {
        console.debug('[hxk] saveDefaultPreferences err: ' + JSON.stringify(err));
      });
    }).catch((err: Error) => {
      console.debug('[hxk] saveDefaultPreferences err: ' + JSON.stringify(err));
    });
  }

  public savePreferences(preferencesName: string, value: ESObject): void {
    let getPreferences: Function =
      GlobalContext.getContext().getObject(CommonConstants.GET_PREFERENCES) as Function;
    getPreferences().then(async (preferences: dataPreferences.Preferences) => {
      await preferences.put(preferencesName, JSON.stringify(value));
      preferences.flush();
    }).catch((err: Error) => {
      console.debug('[hxk] savePreferences err: ' + JSON.stringify(err));
    });
  }

  public async getPreferences(preferenceName: string, defaultValue: ESObject): Promise<string> {
    let getPreferences: Function =
      GlobalContext.getContext().getObject(CommonConstants.GET_PREFERENCES) as Function;
    return await (await getPreferences() as dataPreferences.Preferences)
      .get(preferenceName, JSON.stringify(defaultValue)) as string;
  }

  public async deletePreferences(preferencesName: string): Promise<void> {
    let getPreferences: Function =
      GlobalContext.getContext().getObject(CommonConstants.GET_PREFERENCES) as Function;
    const preferences: dataPreferences.Preferences = await getPreferences();
    let deleteValue = preferences.delete(preferencesName);
    deleteValue.then(() => {
      console.debug('[hxk] deletePreferences succeed.');
    }).catch((err: Error) => {
      console.debug('[hxk] deletePreferences err: ' + JSON.stringify(err));
    });
  }
}

export default new PreferencesUtil();