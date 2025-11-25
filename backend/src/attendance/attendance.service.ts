import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CheckStatusDto, ClockInDto, ClockOutDto } from './dto/attendance-operations.dto';
import { Prisma } from '@prisma/client';
import { ExternalSystemService } from '../external-system/external-system.service';

@Injectable()
export class AttendanceService {
  constructor(
    private prisma: PrismaService,
    private externalSystem: ExternalSystemService,
  ) { }

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

    // Check for today's attendance
    const today = new Date();
    today.setHours(0, 0, 0, 0);
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

    return {
      employee,
      attendance,
      commute_templates: employee.commuteTemplates,
    };
  }

  async clockIn(dto: ClockInDto) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

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
        const externalAttendance =
          await this.externalSystem.registerAttendance({
            attendance: {
              staff_id: attendance.employee.external_staff_id,
              work_day: attendance.date.toISOString().split('T')[0],
              school_id: attendance.school_id,
              commuting_costs: dto.commute_info?.cost || 0,
              another_time: 0, // Default
              total_lesson: dto.total_lesson || 0,
              total_training_lesson: 0, // Default
              deduction_time: 0, // Default
              note: dto.commute_info?.name || '',
            },
            lesson_ids: [], // We don't track specific lessons yet
            total_training_lesson: 0,
          });
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
