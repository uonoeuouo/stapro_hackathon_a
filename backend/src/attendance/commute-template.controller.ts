import { Controller, Get, Post, Body, Param, Delete, Put, ParseIntPipe } from '@nestjs/common';
import { CommuteTemplateService } from './commute-template.service';
import { CreateCommuteTemplateDto, UpdateCommuteTemplateDto } from './dto/commute-template.dto';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('commute-templates')
@Controller('commute-templates')
export class CommuteTemplateController {
    constructor(private readonly commuteTemplateService: CommuteTemplateService) { }

    @Post()
    @ApiOperation({ summary: 'Create a new commute template' })
    create(@Body() createDto: CreateCommuteTemplateDto) {
        return this.commuteTemplateService.create(createDto);
    }

    @Get('employee/:employeeId')
    @ApiOperation({ summary: 'Get all templates for an employee' })
    findAll(@Param('employeeId', ParseIntPipe) employeeId: number) {
        return this.commuteTemplateService.findAll(employeeId);
    }

    @Get(':id')
    @ApiOperation({ summary: 'Get a template by ID' })
    findOne(@Param('id', ParseIntPipe) id: number) {
        return this.commuteTemplateService.findOne(id);
    }

    @Put(':id')
    @ApiOperation({ summary: 'Update a template' })
    update(@Param('id', ParseIntPipe) id: number, @Body() updateDto: UpdateCommuteTemplateDto) {
        return this.commuteTemplateService.update(id, updateDto);
    }

    @Delete(':id')
    @ApiOperation({ summary: 'Delete a template' })
    remove(@Param('id', ParseIntPipe) id: number) {
        return this.commuteTemplateService.remove(id);
    }
}
