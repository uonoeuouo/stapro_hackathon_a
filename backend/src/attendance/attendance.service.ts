import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CheckStatusDto, ClockInDto, ClockOutDto } from './dto/attendance-operations.dto';
import { Prisma } from '@prisma/client';
import {
  ExternalAttendanceDto,
  RegisterAttendanceDto,
} from '../external-system/dto/external-system.dto';
import { ExternalSystemService } from '../external-system/external-system.service';

@Injectable()
export class AttendanceService {
  constructor(
    private prisma: PrismaService,
    private externalSystem: ExternalSystemService,
  ) { }

  private getJstTodayStart(): Date {
    const now = new Date();
    // Add 9 hours to get JST time
    const jstNow = new Date(now.getTime() + 9 * 60 * 60 * 1000);
    // Set to midnight
    jstNow.setUTCHours(0, 0, 0, 0);
    // Subtract 9 hours to get UTC equivalent
    return new Date(jstNow.getTime() - 9 * 60 * 60 * 1000);
  }

  async checkStatus(dto: CheckStatusDto) {
    // Find card and employee through Card table
    const card = await this.prisma.card.findUnique({
      where: { card_id: dto.card_id },
      include: {
        employee: {
          include: { commuteTemplates: true },
        },
      },
    });

    if (!card) {
      throw new NotFoundException('unknown_card');
    }

    if (!card.is_active) {
      throw new BadRequestException('card_inactive');
    }

    const employee = card.employee;

    // Check for today's attendance (JST)
    const today = this.getJstTodayStart();
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const attendance = await this.prisma.attendance.findFirst({
      where: {
        employee_id: employee.id,
        date: {
          gte: today,
          lt: tomorrow,
        },
      },
    });

    let school = null;
    if (attendance) {
      // Fetch school info to get timetables
      try {
        const schools = await this.externalSystem.getSchools();
        school = schools.find((s) => s.id === attendance.school_id);
      } catch (e) {
        // Ignore error if school fetch fails
      }
    }

    return {
      employee,
      attendance,
      commute_templates: employee.commuteTemplates,
      school,
    };
  }

  async clockIn(dto: ClockInDto) {
    const today = this.getJstTodayStart();

    // Check if already clocked in
    const existing = await this.prisma.attendance.findFirst({
      where: {
        employee_id: dto.employee_id,
        date: { gte: today },
      },
    });

    if (existing) {
      throw new BadRequestException('already_clocked_in');
    }

    const attendance = await this.prisma.attendance.create({
      data: {
        employee_id: dto.employee_id,
        date: today,
        clock_in_time: new Date(dto.client_timestamp),
        school_id: dto.school_id,
      },
    });

    return { type: 'clock_in', attendance };
  }

  async clockOut(dto: ClockOutDto) {
    const attendance = await this.prisma.attendance.findUnique({
      where: { id: dto.attendance_id },
      include: { employee: true },
    });

    if (!attendance) {
      throw new NotFoundException('attendance_not_found');
    }

    if (attendance.clock_out_time) {
      throw new BadRequestException('already_clocked_out');
    }

    let externalAttendanceId: number | null = null;

    // Sync with external system if employee is linked
    if (attendance.employee.external_staff_id && attendance.school_id) {
      try {
        const workDay = attendance.date.toISOString().split('T')[0];
        const registerDto: RegisterAttendanceDto = {
          attendance: {
            staff_id: attendance.employee.external_staff_id,
            work_day: workDay,
            school_id: attendance.school_id,
            commuting_costs: dto.commute_info?.cost || 0,
            another_time: dto.another_time || 0,
            total_lesson: dto.total_lesson || 0,
            total_training_lesson: 0,
            deduction_time: 0,
            note: dto.commute_info?.name || '',
          },
          lesson_ids: dto.lesson_ids || [],
          total_training_lesson: 0,
        };
        const externalAttendance =
          await this.externalSystem.registerAttendance(registerDto);
        externalAttendanceId = externalAttendance.id;
      } catch (e) {
        console.error('Failed to sync with external system', e);
        // We continue even if sync fails, but maybe we should flag it?
        // For now, we just log it.
      }
    }

    const updated = await this.prisma.attendance.update({
      where: { id: dto.attendance_id },
      data: {
        clock_out_time: new Date(dto.client_timestamp),
        commute_info: dto.commute_info || {},
        external_attendance_id: externalAttendanceId,
      },
    });

    return { type: 'clock_out', attendance: updated };
  }

  async cancel(id: number) {
    const attendance = await this.prisma.attendance.findUnique({
      where: { id },
    });

    if (!attendance) {
      throw new NotFoundException('attendance_not_found');
    }

    // If clocked out, revert to clocked in
    if (attendance.clock_out_time) {
      // If synced, delete from external system
      if (attendance.external_attendance_id) {
        try {
          await this.externalSystem.deleteAttendance(
            attendance.external_attendance_id,
          );
        } catch (e) {
          console.error('Failed to delete from external system', e);
        }
      }

      const updated = await this.prisma.attendance.update({
        where: { id },
        data: {
          clock_out_time: null,
          commute_info: null as any,
          external_attendance_id: null,
        },
      });
      return { type: 'cancel_clock_out', attendance: updated };
    }

    // If just clocked in, delete the record
    await this.prisma.attendance.delete({
      where: { id },
    });

    return { type: 'cancel_clock_in', attendance: null };
  }
}
