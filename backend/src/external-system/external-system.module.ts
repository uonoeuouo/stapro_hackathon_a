import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { ConfigModule } from '@nestjs/config';
import { ExternalSystemService } from './external-system.service';

@Module({
    imports: [HttpModule, ConfigModule],
    providers: [ExternalSystemService],
    exports: [ExternalSystemService],
})
export class ExternalSystemModule { }
