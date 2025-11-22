import {
    Controller,
    Get,
    Post,
    Patch,
    Delete,
    Param,
    Body,
    ParseIntPipe,
    HttpCode,
    HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { CardService } from './card.service';
import { CreateCardDto } from './dto/create-card.dto';
import { UpdateCardDto } from './dto/update-card.dto';

@ApiTags('cards')
@Controller('employees/:employeeId/cards')
export class CardController {
    constructor(private readonly cardService: CardService) { }

    @Get()
    @ApiOperation({ summary: 'Get all cards for an employee' })
    @ApiResponse({ status: 200, description: 'Returns list of cards' })
    @ApiResponse({ status: 404, description: 'Employee not found' })
    async listCards(@Param('employeeId', ParseIntPipe) employeeId: number) {
        return this.cardService.listCards(employeeId);
    }

    @Post()
    @ApiOperation({ summary: 'Register a new card for an employee' })
    @ApiResponse({ status: 201, description: 'Card created successfully' })
    @ApiResponse({ status: 404, description: 'Employee not found' })
    @ApiResponse({ status: 409, description: 'Card ID already registered' })
    async createCard(
        @Param('employeeId', ParseIntPipe) employeeId: number,
        @Body() dto: CreateCardDto,
    ) {
        return this.cardService.createCard(employeeId, dto);
    }

    @Patch(':cardId')
    @ApiOperation({ summary: 'Update a card' })
    @ApiResponse({ status: 200, description: 'Card updated successfully' })
    @ApiResponse({ status: 404, description: 'Card not found' })
    async updateCard(
        @Param('employeeId', ParseIntPipe) employeeId: number,
        @Param('cardId', ParseIntPipe) cardId: number,
        @Body() dto: UpdateCardDto,
    ) {
        return this.cardService.updateCard(employeeId, cardId, dto);
    }

    @Delete(':cardId')
    @HttpCode(HttpStatus.NO_CONTENT)
    @ApiOperation({ summary: 'Delete a card' })
    @ApiResponse({ status: 204, description: 'Card deleted successfully' })
    @ApiResponse({ status: 404, description: 'Card not found' })
    async deleteCard(
        @Param('employeeId', ParseIntPipe) employeeId: number,
        @Param('cardId', ParseIntPipe) cardId: number,
    ) {
        await this.cardService.deleteCard(employeeId, cardId);
    }
}
