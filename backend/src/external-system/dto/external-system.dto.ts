export class SchoolDto {
    id: number;
    name: string;
    kana: string;
    student: number;
    managed_lesson: number;
    is_opened: boolean;
    opened_on: string;
    closed_on: string | null;
    created_at: string;
    updated_at: string;
}

export class ExternalStaffDto {
    id: number;
    email: string;
    last_name: string;
    first_name: string;
    last_name_kana: string;
    first_name_kana: string;
    role_id: number;
    authority: number;
    status: number;
    commuting_costs: number;
    born_on: string;
    entered_on: string;
    retired_on: string | null;
}

export class ExternalAttendanceDto {
    id: number;
    staff_id: number;
    work_day: string;
    school_id: number;
    school_name: string;
    commuting_costs: number;
    another_time: number;
    total_lesson: number;
    total_training_lesson: number;
    deduction_time: number;
    note: string;
    lessons: { id: number; time: string }[];
    created_at: string;
    updated_at: string;
}

export class LoginDto {
    email: string;
    password: string;
}

export class RegisterAttendanceDto {
    attendance: {
        staff_id: number;
        work_day: string;
        school_id: number;
        commuting_costs: number;
        another_time: number;
        total_lesson: number;
        total_training_lesson: number;
        deduction_time: number;
        note: string;
    };
    lesson_ids: number[];
    total_training_lesson: number;
}
