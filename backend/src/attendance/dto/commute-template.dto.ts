import { ApiProperty, PartialType } from '@nestjs/swagger';
import { IsInt, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateCommuteTemplateDto {
    @ApiProperty({ example: 1, description: 'Employee ID' })
    @IsInt()
    @IsNotEmpty()
    employee_id: number;

    @ApiProperty({ example: 'Train (Home -> Office)', description: 'Name of the template' })
    @IsString()
    @IsNotEmpty()
    name: string;

    @ApiProperty({ example: 500, description: 'Cost in JPY' })
    @IsInt()
    @IsNotEmpty()
    cost: number;

    @ApiProperty({ example: 'Shinjuku -> Tokyo', description: 'Route description', required: false })
    @IsString()
    @IsOptional()
    route_description?: string;
}

export class UpdateCommuteTemplateDto extends PartialType(CreateCommuteTemplateDto) { }
