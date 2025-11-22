import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsBoolean, IsOptional } from 'class-validator';

export class UpdateCardDto {
    @ApiProperty({
        description: 'Optional name for the card',
        example: 'Backup Card',
        required: false,
    })
    @IsString()
    @IsOptional()
    name?: string;

    @ApiProperty({
        description: 'Whether the card is active',
        example: true,
        required: false,
    })
    @IsBoolean()
    @IsOptional()
    is_active?: boolean;
}
