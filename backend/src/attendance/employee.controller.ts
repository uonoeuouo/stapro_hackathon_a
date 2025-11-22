import { Controller, Get } from '@nestjs/common';
import { EmployeeService } from './employee.service';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('employees')
@Controller('employees')
export class EmployeeController {
    constructor(private readonly employeeService: EmployeeService) { }

    @Get()
    @ApiOperation({ summary: 'Get all employees' })
    @ApiResponse({ status: 200, description: 'Return all employees.' })
    async findAll() {
        return this.employeeService.findAll();
    }
}
