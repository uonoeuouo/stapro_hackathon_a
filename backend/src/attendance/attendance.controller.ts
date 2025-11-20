import { Controller, Post, Body, Delete, Param, ParseIntPipe } from '@nestjs/common';
import { AttendanceService } from './attendance.service';
import { CheckStatusDto, ClockInDto, ClockOutDto } from './dto/attendance-operations.dto';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('attendance')
@Controller('attendance')
export class AttendanceController {
  constructor(private readonly attendanceService: AttendanceService) { }

  @Post('status')
  @ApiOperation({ summary: 'Check card status and get employee info' })
  @ApiResponse({ status: 200, description: 'Employee found' })
  @ApiResponse({ status: 404, description: 'Unknown card' })
  checkStatus(@Body() dto: CheckStatusDto) {
    return this.attendanceService.checkStatus(dto);
  }

  @Post('clock-in')
  @ApiOperation({ summary: 'Clock in' })
  clockIn(@Body() dto: ClockInDto) {
    return this.attendanceService.clockIn(dto);
  }

  @Post('clock-out')
  @ApiOperation({ summary: 'Clock out' })
  clockOut(@Body() dto: ClockOutDto) {
    return this.attendanceService.clockOut(dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Cancel last action' })
  cancel(@Param('id', ParseIntPipe) id: number) {
    return this.attendanceService.cancel(id);
  }
}
