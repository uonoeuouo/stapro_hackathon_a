import { Module } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { AttendanceController } from './attendance.controller';
import { CommuteTemplateService } from './commute-template.service';
import { CommuteTemplateController } from './commute-template.controller';
import { CardService } from './card.service';
import { CardController } from './card.controller';
import { EmployeeService } from './employee.service';
import { EmployeeController } from './employee.controller';
import { ExternalSystemModule } from '../external-system/external-system.module';
import { CardsController } from './cards.controller';
import { SchoolsController } from './schools.controller';

@Module({
  imports: [ExternalSystemModule],
  controllers: [
    AttendanceController,
    CommuteTemplateController,
    CardController,
    EmployeeController,
    CardsController,
    SchoolsController,
  ],
  providers: [
    AttendanceService,
    CommuteTemplateService,
    CardService,
    EmployeeService,
  ],
})
export class AttendanceModule { }
