import { Injectable } from '@nestjs/common';

@Injectable()
export class NasService {
  async findAll() {
    return {
      devices: [
        {
          id: 1,
          name: 'Mikrotik Router #1',
          ipAddress: '192.168.1.1',
          type: 'Mikrotik RB4011',
          location: 'Main Office',
          status: 'online',
          connectedUsers: 45,
          sharedSecret: 'testing123',
          ports: {
            auth: 1812,
            accounting: 1813
          },
          lastSeen: new Date().toISOString()
        },
        {
          id: 2,
          name: 'Mikrotik Router #2',
          ipAddress: '192.168.2.1',
          type: 'Mikrotik RB3011',
          location: 'Branch Office',
          status: 'online',
          connectedUsers: 32,
          sharedSecret: 'testing123',
          ports: {
            auth: 1812,
            accounting: 1813
          },
          lastSeen: new Date().toISOString()
        }
      ]
    };
  }

  async findOne(id: number) {
    return {
      id,
      name: 'Mikrotik Router #1',
      ipAddress: '192.168.1.1',
      type: 'Mikrotik RB4011',
      location: 'Main Office',
      status: 'online',
      connectedUsers: 45,
      sharedSecret: 'testing123',
      configuration: {
        radiusServer: '167.172.214.191',
        authPort: 1812,
        accountingPort: 1813,
        coaPort: 3799
      }
    };
  }

  async create(nasData: any) {
    return {
      success: true,
      message: 'NAS device added successfully',
      device: {
        id: Date.now(),
        ...nasData,
        status: 'online',
        createdAt: new Date().toISOString()
      }
    };
  }

  async update(id: number, updateData: any) {
    return {
      success: true,
      message: 'NAS device updated successfully'
    };
  }

  async remove(id: number) {
    return {
      success: true,
      message: 'NAS device removed successfully'
    };
  }

  async restart(id: number) {
    return {
      success: true,
      message: 'NAS device restart command sent'
    };
  }

  async getStatus(id: number) {
    return {
      deviceId: id,
      status: 'online',
      uptime: '15 days, 4 hours',
      cpuUsage: '23%',
      memoryUsage: '45%',
      activeSessions: 45,
      throughput: {
        download: '245 Mbps',
        upload: '89 Mbps'
      }
    };
  }

  async getActiveSessions(id: number) {
    return {
      deviceId: id,
      sessions: [
        {
          username: 'john.doe',
          ipAddress: '192.168.1.100',
          sessionTime: '2h 35m',
          downloadUsage: '1.2 GB',
          uploadUsage: '0.3 GB'
        },
        {
          username: 'sarah.smith',
          ipAddress: '192.168.1.101',
          sessionTime: '1h 15m',
          downloadUsage: '0.8 GB',
          uploadUsage: '0.2 GB'
        }
      ]
    };
  }
}
