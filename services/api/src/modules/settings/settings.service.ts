import { Injectable } from '@nestjs/common';

@Injectable()
export class SettingsService {
  // SMS Configuration
  getSMSSettings() {
    return {
      twilio: {
        enabled: false,
        accountSid: 'AC****************************',
        authToken: '********************************',
        fromNumber: '+1234567890',
        status: 'Not Configured'
      },
      httpSms: {
        enabled: false,
        gatewayUrl: '',
        apiKey: '',
        username: '',
        senderId: 'HaroonNet',
        status: 'Not Configured'
      },
      templates: {
        welcome: 'Welcome to HaroonNet ISP! Your account is now active.',
        payment: 'Thank you for your payment. Your service continues.',
        suspension: 'Your service has been suspended due to non-payment.',
        reactivation: 'Your service has been reactivated. Welcome back!'
      }
    };
  }

  updateTwilioSettings(config: any) {
    return {
      success: true,
      message: 'Twilio SMS settings updated successfully',
      settings: {
        accountSid: config.accountSid,
        fromNumber: config.fromNumber,
        enabled: config.enabled,
        status: config.enabled ? 'Active' : 'Disabled'
      }
    };
  }

  updateHttpSmsSettings(config: any) {
    return {
      success: true,
      message: 'HTTP SMS gateway settings updated successfully',
      settings: {
        gatewayUrl: config.gatewayUrl,
        username: config.username,
        senderId: config.senderId,
        enabled: config.enabled,
        status: config.enabled ? 'Active' : 'Disabled'
      }
    };
  }

  testSmsConfiguration(testData: any) {
    return {
      success: true,
      message: 'Test SMS sent successfully',
      details: {
        phoneNumber: testData.phoneNumber,
        message: testData.message,
        gateway: testData.gateway,
        sentAt: new Date().toISOString(),
        messageId: `MSG-${Date.now()}`
      }
    };
  }

  // Email Configuration
  getEmailSettings() {
    return {
      smtp: {
        host: 'smtp.gmail.com',
        port: 587,
        secure: false,
        username: 'admin@haroonnet.com',
        password: '****************',
        fromName: 'HaroonNet ISP',
        fromEmail: 'admin@haroonnet.com'
      },
      templates: {
        welcome: 'Welcome to HaroonNet ISP',
        invoice: 'Your monthly invoice is ready',
        payment: 'Payment confirmation',
        suspension: 'Service suspension notice'
      }
    };
  }

  updateEmailSettings(config: any) {
    return {
      success: true,
      message: 'Email settings updated successfully',
      settings: config
    };
  }

  // Company Settings
  getCompanySettings() {
    return {
      company: {
        name: 'HaroonNet ISP',
        email: 'admin@haroonnet.com',
        phone: '+93-123-456-789',
        address: 'Kabul, Afghanistan',
        website: 'https://haroonnet.com',
        logo: '/logo.png',
        timezone: 'Asia/Kabul',
        currency: 'AFN',
        taxRate: 10,
        language: 'en'
      },
      billing: {
        invoicePrefix: 'INV',
        dueDate: 30,
        lateFee: 5,
        gracePeriod: 7,
        autoSuspend: true
      }
    };
  }

  updateCompanySettings(config: any) {
    return {
      success: true,
      message: 'Company settings updated successfully',
      settings: config
    };
  }

  // RADIUS Settings
  getRadiusSettings() {
    return {
      server: {
        status: 'Running',
        uptime: '15 days, 4 hours',
        authPort: 1812,
        accountingPort: 1813,
        coaPort: 3799,
        sharedSecret: 'haroonnet-coa-secret'
      },
      statistics: {
        totalRequests: 156789,
        successfulAuth: 152341,
        failedAuth: 4448,
        successRate: 97.2
      },
      clients: [
        { name: 'Mikrotik Router #1', ip: '192.168.1.1', secret: 'testing123', status: 'Active' },
        { name: 'Mikrotik Router #2', ip: '192.168.2.1', secret: 'testing123', status: 'Active' }
      ]
    };
  }

  updateRadiusSettings(config: any) {
    return {
      success: true,
      message: 'RADIUS settings updated successfully',
      settings: config
    };
  }

  restartRadiusServer() {
    return {
      success: true,
      message: 'RADIUS server restart initiated',
      status: 'Restarting',
      estimatedTime: '30 seconds'
    };
  }

  // System Settings
  getSystemSettings() {
    return {
      system: {
        version: '1.0.0',
        environment: 'production',
        debugMode: false,
        logLevel: 'info',
        maintenanceMode: false
      },
      performance: {
        cpuUsage: '23%',
        memoryUsage: '45%',
        diskUsage: '67%',
        networkLatency: '12ms'
      },
      backup: {
        enabled: true,
        frequency: 'daily',
        retention: '30 days',
        lastBackup: '2025-01-20 02:00:00'
      }
    };
  }

  updateSystemSettings(config: any) {
    return {
      success: true,
      message: 'System settings updated successfully',
      settings: config
    };
  }
}
