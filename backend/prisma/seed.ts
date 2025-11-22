import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Seeding database...');

    // Create Employees (without card_id)
    const employee1 = await prisma.employee.create({
        data: {
            name: 'Taro Yamada',
        },
    });

    const employee2 = await prisma.employee.create({
        data: {
            name: 'Hanako Suzuki',
        },
    });

    const employee3 = await prisma.employee.create({
        data: {
            name: 'Ichiro Tanaka',
        },
    });

    console.log({ employee1, employee2, employee3 });

    // Create Cards for employees
    await prisma.card.createMany({
        data: [
            // Employee 1 - Multiple cards
            {
                employee_id: employee1.id,
                card_id: '12345678',
                name: 'Main Card',
                is_active: true,
            },
            {
                employee_id: employee1.id,
                card_id: '12345679',
                name: 'Backup Card',
                is_active: true,
            },
            // Employee 2 - Single card
            {
                employee_id: employee2.id,
                card_id: '87654321',
                name: 'Main Card',
                is_active: true,
            },
            // Employee 3 - Multiple cards with one inactive
            {
                employee_id: employee3.id,
                card_id: 'CARD001',
                name: 'Old Card',
                is_active: false,
            },
            {
                employee_id: employee3.id,
                card_id: 'CARD002',
                name: 'Current Card',
                is_active: true,
            },
        ],
    });

    console.log('Cards created.');

    // Create Commute Templates for Employee 1
    await prisma.commuteTemplate.createMany({
        data: [
            {
                employee_id: employee1.id,
                name: 'Train (Home -> Office)',
                cost: 500,
                route_description: 'Shinjuku -> Tokyo',
            },
            {
                employee_id: employee1.id,
                name: 'Bus (Station -> Office)',
                cost: 220,
            },
        ],
    });

    // Create Commute Templates for Employee 2
    await prisma.commuteTemplate.createMany({
        data: [
            {
                employee_id: employee2.id,
                name: 'Subway',
                cost: 180,
            },
        ],
    });

    // Create Commute Templates for Employee 3
    await prisma.commuteTemplate.createMany({
        data: [
            {
                employee_id: employee3.id,
                name: 'Train',
                cost: 300,
            },
        ],
    });

    console.log('Seeding finished.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
