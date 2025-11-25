import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsEmail } from 'class-validator';

export class RegisterCardWithAuthDto {
    @ApiProperty({
        description: 'The NFC card ID',
        example: 'CARD12345678',
    })
    @IsString()
    @IsNotEmpty()
    cardId: string;

    @ApiProperty({
        description: 'Email for external system login',
        example: 'user@example.com',
    })
    @IsEmail()
    @IsNotEmpty()
    email: string;

    @ApiProperty({
        description: 'Password for external system login',
        example: 'password123',
    })
    @IsString()
    @IsNotEmpty()
    password: string;
}
