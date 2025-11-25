import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { ExternalSystemService } from '../external-system/external-system.service';

@ApiTags('schools')
@Controller('schools')
export class SchoolsController {
    constructor(private readonly externalSystem: ExternalSystemService) { }

    @Get()
    @ApiOperation({ summary: 'Get list of schools (classrooms)' })
    @ApiResponse({ status: 200, description: 'Returns list of schools' })
    async getSchools() {
        return this.externalSystem.getSchools();
    }
}
