import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { NasService } from './nas.service';

@Controller('nas')
export class NasController {
  constructor(private readonly nasService: NasService) {}

  @Get()
  async getAllNasDevices() {
    return this.nasService.findAll();
  }

  @Get(':id')
  async getNasDevice(@Param('id') id: string) {
    return this.nasService.findOne(+id);
  }

  @Post()
  async createNasDevice(@Body() nasData: any) {
    return this.nasService.create(nasData);
  }

  @Put(':id')
  async updateNasDevice(@Param('id') id: string, @Body() updateData: any) {
    return this.nasService.update(+id, updateData);
  }

  @Delete(':id')
  async deleteNasDevice(@Param('id') id: string) {
    return this.nasService.remove(+id);
  }

  @Post(':id/restart')
  async restartNasDevice(@Param('id') id: string) {
    return this.nasService.restart(+id);
  }

  @Get(':id/status')
  async getNasStatus(@Param('id') id: string) {
    return this.nasService.getStatus(+id);
  }

  @Get(':id/sessions')
  async getActiveSessions(@Param('id') id: string) {
    return this.nasService.getActiveSessions(+id);
  }
}
