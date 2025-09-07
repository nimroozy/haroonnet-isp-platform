import { Injectable } from '@nestjs/common';

@Injectable()
export class CustomersService {
  async findAll(query: any) {
    // Mock data - replace with actual database queries
    return {
      customers: [
        {
          id: 1,
          username: 'john.doe',
          email: 'john@example.com',
          fullName: 'John Doe',
          phone: '+93-123-456-789',
          address: 'Kabul, Afghanistan',
          servicePlan: 'premium',
          status: 'active',
          createdAt: '2024-01-15',
          lastLogin: '2024-01-20',
          usage: '15.2 GB'
        },
        {
          id: 2,
          username: 'sarah.smith',
          email: 'sarah@example.com',
          fullName: 'Sarah Smith',
          phone: '+93-987-654-321',
          address: 'Herat, Afghanistan',
          servicePlan: 'basic',
          status: 'suspended',
          createdAt: '2024-01-10',
          lastLogin: '2024-01-18',
          usage: '8.7 GB'
        }
      ],
      total: 1247,
      page: 1,
      limit: 10
    };
  }

  async findOne(id: number) {
    return {
      id,
      username: 'john.doe',
      email: 'john@example.com',
      fullName: 'John Doe',
      phone: '+93-123-456-789',
      address: 'Kabul, Afghanistan',
      servicePlan: 'premium',
      status: 'active',
      createdAt: '2024-01-15',
      lastLogin: '2024-01-20',
      totalUsage: '145.7 GB',
      monthlyUsage: '15.2 GB'
    };
  }

  async create(customerData: any) {
    return {
      success: true,
      message: 'Customer created successfully',
      customer: {
        id: Date.now(),
        ...customerData,
        status: 'active',
        createdAt: new Date().toISOString()
      }
    };
  }

  async update(id: number, updateData: any) {
    return {
      success: true,
      message: 'Customer updated successfully',
      customer: { id, ...updateData }
    };
  }

  async remove(id: number) {
    return {
      success: true,
      message: 'Customer deleted successfully'
    };
  }

  async suspend(id: number) {
    return {
      success: true,
      message: 'Customer suspended successfully'
    };
  }

  async activate(id: number) {
    return {
      success: true,
      message: 'Customer activated successfully'
    };
  }

  async getUsageStats(id: number) {
    return {
      customerId: id,
      currentMonth: {
        download: '15.2 GB',
        upload: '2.8 GB',
        total: '18.0 GB'
      },
      dailyUsage: [
        { date: '2024-01-15', usage: 1.2 },
        { date: '2024-01-16', usage: 1.8 },
        { date: '2024-01-17', usage: 2.1 },
        { date: '2024-01-18', usage: 1.5 },
        { date: '2024-01-19', usage: 2.3 },
        { date: '2024-01-20', usage: 1.9 }
      ],
      packageLimit: '500 GB',
      percentageUsed: 3.6
    };
  }
}
