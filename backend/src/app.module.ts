import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AttendanceModule } from './attendance/attendance.module';
import { ExternalSystemModule } from './external-system/external-system.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AttendanceModule,
    ExternalSystemModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
