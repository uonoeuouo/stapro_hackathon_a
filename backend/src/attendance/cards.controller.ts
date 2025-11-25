import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { CardService } from './card.service';
import { RegisterCardWithAuthDto } from './dto/register-card-auth.dto';

@ApiTags('cards')
@Controller('cards')
export class CardsController {
    constructor(private readonly cardService: CardService) { }

    @Post('register-auth')
    @ApiOperation({ summary: 'Register a new card with external authentication' })
    @ApiResponse({ status: 201, description: 'Card registered successfully' })
    @ApiResponse({ status: 401, description: 'Invalid credentials' })
    @ApiResponse({ status: 409, description: 'Card already registered' })
    async registerCardWithAuth(@Body() dto: RegisterCardWithAuthDto) {
        return this.cardService.registerCardWithAuth(dto);
    }
}
