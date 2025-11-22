import {
    Injectable,
    NotFoundException,
    ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCardDto } from './dto/create-card.dto';
import { UpdateCardDto } from './dto/update-card.dto';

@Injectable()
export class CardService {
    constructor(private prisma: PrismaService) { }

    async listCards(employeeId: number) {
        const employee = await this.prisma.employee.findUnique({
            where: { id: employeeId },
        });

        if (!employee) {
            throw new NotFoundException(
                `Employee with ID ${employeeId} not found`,
            );
        }

        return this.prisma.card.findMany({
            where: { employee_id: employeeId },
            orderBy: { createdAt: 'desc' },
        });
    }

    async createCard(employeeId: number, dto: CreateCardDto) {
        // Check if employee exists
        const employee = await this.prisma.employee.findUnique({
            where: { id: employeeId },
        });

        if (!employee) {
            throw new NotFoundException(
                `Employee with ID ${employeeId} not found`,
            );
        }

        // Check if card_id already exists
        const existingCard = await this.prisma.card.findUnique({
            where: { card_id: dto.cardId },
        });

        if (existingCard) {
            throw new ConflictException(
                `Card with ID ${dto.cardId} is already registered`,
            );
        }

        return this.prisma.card.create({
            data: {
                employee_id: employeeId,
                card_id: dto.cardId,
                name: dto.name,
            },
        });
    }

    async updateCard(employeeId: number, cardId: number, dto: UpdateCardDto) {
        const card = await this.prisma.card.findFirst({
            where: {
                id: cardId,
                employee_id: employeeId,
            },
        });

        if (!card) {
            throw new NotFoundException(
                `Card with ID ${cardId} not found for employee ${employeeId}`,
            );
        }

        return this.prisma.card.update({
            where: { id: cardId },
            data: dto,
        });
    }

    async deleteCard(employeeId: number, cardId: number) {
        const card = await this.prisma.card.findFirst({
            where: {
                id: cardId,
                employee_id: employeeId,
            },
        });

        if (!card) {
            throw new NotFoundException(
                `Card with ID ${cardId} not found for employee ${employeeId}`,
            );
        }

        await this.prisma.card.delete({
            where: { id: cardId },
        });
    }

    async findByCardId(cardId: string) {
        const card = await this.prisma.card.findUnique({
            where: { card_id: cardId, is_active: true },
            include: { employee: true },
        });

        return card;
    }
}
