import WeatherData from './WeatherData';

/**
 * 天气请求结果数据类型。与高德地图天气 API 请求结果向对应。
 */
export default interface WeatherResult {
  status: string;
  count: string;
  info: string;
  infocode: string;
  lives: Array<WeatherData>;
}