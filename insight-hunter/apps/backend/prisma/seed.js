const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcrypt");
const prisma = new PrismaClient();

async function main(){
  const hashed = await bcrypt.hash("password123",10);
  await prisma.user.upsert({
    where:{email:"demo@insighthunter.com"},
    update:{},
    create:{ email:"demo@insighthunter.com", password:hashed, demoMode:true }
  });
  console.log("✅ Dummy user seeded: demo@insighthunter.com / password123");
}
main().finally(()=>prisma.$disconnect());
