import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { lastValueFrom } from 'rxjs';
import {
    SchoolDto,
    ExternalStaffDto,
    ExternalAttendanceDto,
    LoginDto,
    RegisterAttendanceDto,
} from './dto/external-system.dto';

@Injectable()
export class ExternalSystemService {
    private readonly logger = new Logger(ExternalSystemService.name);
    private readonly baseUrl: string;
    private readonly apiToken: string;

    constructor(
        private readonly httpService: HttpService,
        private readonly configService: ConfigService,
    ) {
        this.baseUrl = 'https://staging.system.start-programming.net/api/v1';
        this.apiToken = this.configService.get<string>('API_TOKEN') || '';
    }

    private get headers() {
        return {
            Authorization: `Bearer ${this.apiToken}`,
            'Content-Type': 'application/json',
        };
    }

    async getSchools(): Promise<SchoolDto[]> {
        try {
            const response = await lastValueFrom(
                this.httpService.get(`${this.baseUrl}/schools`, {
                    headers: this.headers,
                }),
            );
            return response.data.schools;
        } catch (error) {
            this.logger.error('Failed to get schools', error);
            throw error;
        }
    }

    async login(dto: LoginDto): Promise<ExternalStaffDto> {
        try {
            const response = await lastValueFrom(
                this.httpService.post(`${this.baseUrl}/auth/login`, dto, {
                    headers: this.headers,
                }),
            );
            return response.data;
        } catch (error) {
            this.logger.error('Failed to login', error);
            if (error.response?.status === 401) {
                throw new UnauthorizedException('Invalid credentials');
            }
            throw error;
        }
    }

    async registerAttendance(
        dto: RegisterAttendanceDto,
    ): Promise<ExternalAttendanceDto> {
        try {
            const response = await lastValueFrom(
                this.httpService.post(`${this.baseUrl}/attendances`, dto, {
                    headers: this.headers,
                }),
            );
            return response.data.attendance;
        } catch (error) {
            this.logger.error('Failed to register attendance', error);
            throw error;
        }
    }

    async deleteAttendance(id: number): Promise<void> {
        try {
            await lastValueFrom(
                this.httpService.delete(`${this.baseUrl}/attendances/${id}`, {
                    headers: this.headers,
                }),
            );
        } catch (error) {
            this.logger.error(`Failed to delete attendance ${id}`, error);
            throw error;
        }
    }
}
