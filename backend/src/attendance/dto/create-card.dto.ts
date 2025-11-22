import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateCardDto {
    @ApiProperty({
        description: 'The NFC card ID',
        example: 'CARD12345678',
    })
    @IsString()
    @IsNotEmpty()
    cardId: string;

    @ApiProperty({
        description: 'Optional name for the card',
        example: 'Main Card',
        required: false,
    })
    @IsString()
    @IsOptional()
    name?: string;
}
