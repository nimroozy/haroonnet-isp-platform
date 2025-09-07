import { Controller, Get, Post, Put, Body } from '@nestjs/common';
import { SettingsService } from './settings.service';

@Controller('settings')
export class SettingsController {
  constructor(private readonly settingsService: SettingsService) {}

  // SMS Configuration
  @Get('sms')
  async getSMSSettings() {
    return this.settingsService.getSMSSettings();
  }

  @Put('sms/twilio')
  async updateTwilioSettings(@Body() twilioConfig: any) {
    return this.settingsService.updateTwilioSettings(twilioConfig);
  }

  @Put('sms/http')
  async updateHttpSmsSettings(@Body() httpSmsConfig: any) {
    return this.settingsService.updateHttpSmsSettings(httpSmsConfig);
  }

  @Post('sms/test')
  async testSmsConfiguration(@Body() testData: any) {
    return this.settingsService.testSmsConfiguration(testData);
  }

  // Email Configuration
  @Get('email')
  async getEmailSettings() {
    return this.settingsService.getEmailSettings();
  }

  @Put('email')
  async updateEmailSettings(@Body() emailConfig: any) {
    return this.settingsService.updateEmailSettings(emailConfig);
  }

  // Company Settings
  @Get('company')
  async getCompanySettings() {
    return this.settingsService.getCompanySettings();
  }

  @Put('company')
  async updateCompanySettings(@Body() companyConfig: any) {
    return this.settingsService.updateCompanySettings(companyConfig);
  }

  // RADIUS Settings
  @Get('radius')
  async getRadiusSettings() {
    return this.settingsService.getRadiusSettings();
  }

  @Put('radius')
  async updateRadiusSettings(@Body() radiusConfig: any) {
    return this.settingsService.updateRadiusSettings(radiusConfig);
  }

  @Post('radius/restart')
  async restartRadiusServer() {
    return this.settingsService.restartRadiusServer();
  }

  // System Settings
  @Get('system')
  async getSystemSettings() {
    return this.settingsService.getSystemSettings();
  }

  @Put('system')
  async updateSystemSettings(@Body() systemConfig: any) {
    return this.settingsService.updateSystemSettings(systemConfig);
  }
}
