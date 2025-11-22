import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class EmployeeService {
    constructor(private prisma: PrismaService) { }

    async findAll() {
        return this.prisma.employee.findMany({
            orderBy: { id: 'asc' },
        });
    }
}
