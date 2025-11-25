import { IsString, IsNotEmpty, IsInt, IsOptional, IsNumber } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CheckStatusDto {
    @ApiProperty({ example: '0123456789ABCDEF' })
    @IsString()
    @IsNotEmpty()
    card_id: string;

    @ApiProperty({ example: 'iPad-01' })
    @IsString()
    @IsNotEmpty()
    terminal_id: string;

    @ApiProperty({ example: '2023-10-27T09:00:00Z' })
    @IsString()
    @IsNotEmpty()
    client_timestamp: string;
}

export class ClockInDto {
    @ApiProperty({ example: 1 })
    @IsInt()
    @IsNotEmpty()
    employee_id: number;

    @ApiProperty({ example: 'iPad-01' })
    @IsString()
    @IsNotEmpty()
    terminal_id: string;

    @ApiProperty({ example: 1 })
    @IsInt()
    @IsNotEmpty()
    school_id: number;

    @ApiProperty({ example: '2023-10-27T09:00:00Z' })
    @IsString()
    @IsNotEmpty()
    client_timestamp: string;
}

export class ClockOutDto {
    @ApiProperty({ example: 1 })
    @IsInt()
    @IsNotEmpty()
    attendance_id: number;

    @ApiProperty({ example: { template_id: 1, cost: 500 } })
    @IsOptional()
    commute_info?: any;

    @ApiProperty({ example: 4 })
    @IsInt()
    @IsOptional()
    total_lesson?: number;

    @ApiProperty({ example: '2023-10-27T18:00:00Z' })
    @IsString()
    @IsNotEmpty()
    client_timestamp: string;
}
