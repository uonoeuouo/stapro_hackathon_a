import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Seeding database...');

    // Create Employees
    const employee1 = await prisma.employee.upsert({
        where: { card_id: '12345678' },
        update: {},
        create: {
            name: 'Taro Yamada',
            card_id: '12345678',
        },
    });

    const employee2 = await prisma.employee.upsert({
        where: { card_id: '87654321' },
        update: {},
        create: {
            name: 'Hanako Suzuki',
            card_id: '87654321',
        },
    });

    console.log({ employee1, employee2 });

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
