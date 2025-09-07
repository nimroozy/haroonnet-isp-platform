import { Controller, Get, Post, Put, Delete, Body, Param, Query } from '@nestjs/common';
import { CustomersService } from './customers.service';

@Controller('customers')
export class CustomersController {
  constructor(private readonly customersService: CustomersService) {}

  @Get()
  async getAllCustomers(@Query() query: any) {
    return this.customersService.findAll(query);
  }

  @Get(':id')
  async getCustomer(@Param('id') id: string) {
    return this.customersService.findOne(+id);
  }

  @Post()
  async createCustomer(@Body() customerData: any) {
    return this.customersService.create(customerData);
  }

  @Put(':id')
  async updateCustomer(@Param('id') id: string, @Body() updateData: any) {
    return this.customersService.update(+id, updateData);
  }

  @Delete(':id')
  async deleteCustomer(@Param('id') id: string) {
    return this.customersService.remove(+id);
  }

  @Put(':id/suspend')
  async suspendCustomer(@Param('id') id: string) {
    return this.customersService.suspend(+id);
  }

  @Put(':id/activate')
  async activateCustomer(@Param('id') id: string) {
    return this.customersService.activate(+id);
  }

  @Get(':id/usage')
  async getCustomerUsage(@Param('id') id: string) {
    return this.customersService.getUsageStats(+id);
  }
}
