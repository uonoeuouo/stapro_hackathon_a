import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AttendanceModule } from './attendance/attendance.module';

@Module({
  imports: [PrismaModule, AttendanceModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
