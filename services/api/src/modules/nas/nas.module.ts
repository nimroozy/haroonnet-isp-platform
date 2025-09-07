import { Module } from '@nestjs/common';
import { NasController } from './nas.controller';
import { NasService } from './nas.service';

@Module({
  controllers: [NasController],
  providers: [NasService],
  exports: [NasService],
})
export class NasModule {}
