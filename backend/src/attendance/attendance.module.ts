import { Module } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { AttendanceController } from './attendance.controller';
import { CommuteTemplateService } from './commute-template.service';
import { CommuteTemplateController } from './commute-template.controller';

@Module({
  controllers: [AttendanceController, CommuteTemplateController],
  providers: [AttendanceService, CommuteTemplateService],
})
export class AttendanceModule { }
