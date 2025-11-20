import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCommuteTemplateDto, UpdateCommuteTemplateDto } from './dto/commute-template.dto';

@Injectable()
export class CommuteTemplateService {
    constructor(private prisma: PrismaService) { }

    async create(dto: CreateCommuteTemplateDto) {
        return this.prisma.commuteTemplate.create({
            data: dto,
        });
    }

    async findAll(employeeId: number) {
        return this.prisma.commuteTemplate.findMany({
            where: { employee_id: employeeId },
            orderBy: { createdAt: 'asc' },
        });
    }

    async findOne(id: number) {
        return this.prisma.commuteTemplate.findUnique({
            where: { id },
        });
    }

    async update(id: number, dto: UpdateCommuteTemplateDto) {
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const { employee_id, ...rest } = dto;

        // Only update the fields that should be updatable (name, cost, route_description)
        // Do not update the employee relationship
        return this.prisma.commuteTemplate.update({
            where: { id },
            data: rest,
        });
    }

    async remove(id: number) {
        return this.prisma.commuteTemplate.delete({
            where: { id },
        });
    }
}
