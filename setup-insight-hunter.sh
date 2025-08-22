#!/bin/bash
set -e

echo -e "\033[1;33m"
echo "========================================="
echo " 🚀 Setting up Insight Hunter "
echo "========================================="
echo -e "\033[0m"

# -------------------------------
# ENV Vars
# -------------------------------
read -p "Enter DATABASE_URL (default: local postgres): " DB_URL
DB_URL=${DB_URL:-"postgresql://USER:PASSWORD@localhost:5432/insight_hunter"}

JWT_SECRET="supersecretjwtkey"
CF_KEY="your-cloudflare-api-key"

# -------------------------------
# Folder Structure
# -------------------------------
mkdir -p insight-hunter
cd insight-hunter
mkdir -p apps/{backend/{src,prisma},frontend/{app,src/components,public}} workers docs/mockups

# =========================================
# 📑 Docs
# =========================================
cat > docs/demo-data.csv << 'EOF'
Date,Category,Description,Amount
2025-01-02,Revenue,Product Sale,5000
2025-01-05,Expense,Office Rent,-1200
2025-01-06,Expense,Marketing,-800
2025-01-10,Expense,Salaries,-3000
2025-01-15,Revenue,Product Sale,7000
2025-01-22,Revenue,Service Income,3500
2025-01-25,Expense,Travel,-600
EOF

echo "(Manual exported separately)" > docs/InsightHunter-Manual.pdf

cat > README.md << EOF
# Insight Hunter

🚀 Auto-CFO style financial insights for small businesses.

## Quickstart
\`\`\`bash
chmod +x setup-insight-hunter.sh
./setup-insight-hunter.sh
\`\`\`

- Frontend: http://localhost:3000  
- Backend: http://localhost:4000  

### Demo Account
- Email: demo@insighthunter.com  
- Password: password123

📖 Full manual: docs/InsightHunter-Manual.pdf
EOF

# =========================================
# ⚙️ Backend
# =========================================
cd apps/backend
npm init -y >/dev/null
npm install express cors prisma @prisma/client bcrypt jsonwebtoken body-parser >/dev/null

# Prisma schema
cat > prisma/schema.prisma << EOF
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id         String   @id @default(cuid())
  email      String   @unique
  password   String
  demoMode   Boolean  @default(true)
  resetToken String?
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
}
EOF

# Backend index.js
cat > src/index.js << 'EOF'
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

const app = express();
app.use(cors());
app.use(bodyParser.json());

const JWT_SECRET = process.env.JWT_SECRET || "supersecretjwtkey";

function authenticateToken(req,res,next){
  const token = req.headers["authorization"]?.split(" ")[1];
  if (!token) return res.sendStatus(401);
  jwt.verify(token, JWT_SECRET, (err,user)=>{
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

app.get("/", (req,res)=>res.json({status:"Backend running"}));

app.post("/auth/register", async (req,res)=>{
  const { email, password } = req.body;
  const hashed = await bcrypt.hash(password,10);
  try {
    const user = await prisma.user.create({ data: { email, password: hashed } });
    res.json(user);
  } catch {
    res.status(400).json({error:"User exists"});
  }
});

app.post("/auth/login", async (req,res)=>{
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({where:{email}});
  if (!user) return res.status(400).json({error:"Invalid credentials"});
  const match = await bcrypt.compare(password,user.password);
  if (!match) return res.status(400).json({error:"Invalid credentials"});
  const token = jwt.sign({id:user.id,email:user.email},JWT_SECRET,{expiresIn:"1d"});
  res.json({token,user});
});

app.post("/auth/forgot", async (req,res)=>{
  const { email } = req.body;
  const token = Math.random().toString(36).substring(2);
  try {
    await prisma.user.update({ where:{email}, data:{resetToken:token} });
    res.json({message:"Reset token generated", token});
  } catch {
    res.status(400).json({error:"No such user"});
  }
});

app.post("/auth/reset", async (req,res)=>{
  const { token, password } = req.body;
  const hashed = await bcrypt.hash(password,10);
  const user = await prisma.user.updateMany({
    where:{resetToken:token},
    data:{password:hashed, resetToken:null}
  });
  if (!user.count) return res.status(400).json({error:"Invalid token"});
  res.json({message:"Password reset"});
});

app.patch("/users/:id/demo-mode", authenticateToken, async (req,res)=>{
  const { demoMode } = req.body;
  const { id } = req.params;
  if (req.user.id !== id) return res.sendStatus(403);
  const user = await prisma.user.update({ where: { id }, data: { demoMode } });
  res.json(user);
});

app.get("/reports", authenticateToken, async (req,res)=>{
  res.json({
    insights:[
      "Revenue grew 12% this month",
      "Expenses trending lower than last quarter",
      "Healthy cash flow maintained"
    ]
  });
});

const PORT=4000;
app.listen(PORT,()=>console.log("Backend running on "+PORT));
EOF

# Seed
cat > prisma/seed.js << 'EOF'
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
EOF

# Backend env
cat > .env << EOF
DATABASE_URL=$DB_URL
JWT_SECRET=$JWT_SECRET
EOF

cd ../../..

# =========================================
# ⚡ Workers
# =========================================
cd workers
cat > index.js << 'EOF'
export default {
  async fetch() {
    return new Response("Insight Hunter Worker Active");
  }
}
EOF

cat > .dev.vars << EOF
CLOUDFLARE_API_KEY=$CF_KEY
EOF
cd ..

# =========================================
# 🎨 Frontend (manual scaffold)
# =========================================
cd apps/frontend

# package.json
cat > package.json << 'EOF'
{
  "name": "frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "axios": "^1.6.7",
    "chart.js": "^4.4.1",
    "react-chartjs-2": "^5.2.0",
    "next": "14.2.4",
    "react": "18.3.1",
    "react-dom": "18.3.1"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.3",
    "typescript": "^5.4.5"
  }
}
EOF

# tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom","dom.iterable","esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": false,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true
  },
  "include": ["next-env.d.ts","**/*.ts","**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF

# next.config.js
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {};
module.exports = nextConfig;
EOF

# postcss.config.js
cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# tailwind.config.ts
cat > tailwind.config.ts << 'EOF'
import type { Config } from "tailwindcss";
const config: Config = {
  content: ["./app/**/*.{js,ts,jsx,tsx}","./src/**/*.{js,ts,jsx,tsx}"],
  theme: { extend: { colors: { brand: { DEFAULT: "#ea580c", dark: "#9a3412" } } } },
  plugins: [],
};
export default config;
EOF

# Globals
cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body { @apply bg-gray-100 text-gray-900; }
EOF

# Layout
cat > app/layout.tsx << 'EOF'
import "./globals.css";
import { ReactNode } from "react";

export const metadata = { title: "Insight Hunter", description: "AI-powered financial insights" };

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
EOF

# Components
mkdir -p src/components
cat > src/components/Layout.tsx << 'EOF'
"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function Layout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const handleLogout = () => { localStorage.removeItem("token"); router.push("/login"); };

  return (
    <div className="flex min-h-screen bg-gray-100">
      <aside className="w-64 bg-white shadow-md">
        <div className="p-4 font-bold text-orange-600 text-lg">Insight Hunter</div>
        <nav className="space-y-2 px-4">
          <Link href="/dashboard" className="block hover:text-orange-600">Dashboard</Link>
          <Link href="/reports" className="block hover:text-orange-600">Reports</Link>
          <Link href="/settings" className="block hover:text-orange-600">Settings</Link>
          <button onClick={handleLogout} className="mt-4 w-full text-left text-red-600">Logout</button>
        </nav>
      </aside>
      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}
EOF

cat > src/components/DemoBadge.tsx << 'EOF'
export default function DemoBadge() {
  return <div className="bg-orange-100 border border-orange-600 text-orange-700 px-3 py-1 rounded text-sm mb-4">
    Demo Mode ON – Sample data shown
  </div>;
}
EOF

cat > src/components/Insights.tsx << 'EOF'
interface Props { insights: string[] }
export default function Insights({ insights }: Props) {
  return (
    <div className="mt-4 grid gap-4 md:grid-cols-2">
      {insights.map((insight, i) => (
        <div key={i} className="p-4 bg-white rounded shadow border-l-4 border-orange-600">
          <p className="text-gray-800">{insight}</p>
        </div>
      ))}
    </div>
  );
}
EOF

# Pages
cat > app/page.tsx << 'EOF'
import Link from "next/link";
export default function HomePage() {
  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-orange-500 to-orange-700 text-white">
      <div className="text-center">
        <h1 className="text-4xl font-bold mb-4">Welcome to Insight Hunter</h1>
        <p className="mb-6">Your AI-powered financial insights dashboard</p>
        <Link href="/login" className="px-4 py-2 bg-white text-orange-600 rounded">Get Started</Link>
      </div>
    </div>
  );
}
EOF

cat > app/login.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
export default function LoginPage() {
  const [email,setEmail]=useState(""); const [password,setPassword]=useState("");
  const router = useRouter();
  const handleLogin = async (e:any)=>{
    e.preventDefault();
    const res = await fetch("http://localhost:4000/auth/login",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email,password})});
    const data = await res.json();
    if (data.token){ localStorage.setItem("token",data.token); router.push("/dashboard"); }
    else alert("Login failed");
  };
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form onSubmit={handleLogin} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Login</h1>
        <input type="email" placeholder="Email" className="w-full mb-2 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <input type="password" placeholder="Password" className="w-full mb-4 p-2 border rounded" value={password} onChange={e=>setPassword(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Login</button>
      </form>
    </div>
  );
}
EOF

cat > app/register.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
export default function RegisterPage() {
  const [email,setEmail]=useState(""); const [password,setPassword]=useState("");
  const router = useRouter();
  const handleRegister = async (e:any)=>{
    e.preventDefault();
    await fetch("http://localhost:4000/auth/register",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email,password})});
    router.push("/login");
  };
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form onSubmit={handleRegister} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Register</h1>
        <input type="email" placeholder="Email" className="w-full mb-2 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <input type="password" placeholder="Password" className="w-full mb-4 p-2 border rounded" value={password} onChange={e=>setPassword(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Register</button>
      </form>
    </div>
  );
}
EOF

cat > app/forgot.tsx << 'EOF'
"use client";
import { useState } from "react";
export default function ForgotPage() {
  const [email,setEmail]=useState("");
  const handleSubmit = async (e:any)=>{
    e.preventDefault();
    const res = await fetch("http://localhost:4000/auth/forgot",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email})});
    const data = await res.json(); alert(data.message || data.error);
  };
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Forgot Password</h1>
        <input type="email" placeholder="Email" className="w-full mb-4 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Send Reset</button>
      </form>
    </div>
  );
}
EOF

cat > app/reset.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
export default function ResetPage() {
  const [token,setToken]=useState(""); const [password,setPassword]=useState("");
  const router = useRouter();
  const handleSubmit = async (e:any)=>{
    e.preventDefault();
    const res = await fetch("http://localhost:4000/auth/reset",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({token,password})});
    const data = await res.json(); alert(data.message || data.error); router.push("/login");
  };
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-
      #!/bin/bash
set -e

echo -e "\033[1;33m"
echo "========================================="
echo " 🚀 Setting up Insight Hunter "
echo "========================================="
echo -e "\033[0m"

# -------------------------------
# ENV Vars
# -------------------------------
read -p "Enter DATABASE_URL (default: local postgres): " DB_URL
DB_URL=${DB_URL:-"postgresql://USER:PASSWORD@localhost:5432/insight_hunter"}

JWT_SECRET="supersecretjwtkey"
CF_KEY="your-cloudflare-api-key"

# -------------------------------
# Folder Structure
# -------------------------------
mkdir -p insight-hunter
cd insight-hunter
mkdir -p apps/{backend/{src,prisma},frontend/{app,src/components,public}} workers docs/mockups

# =========================================
# 📑 Docs
# =========================================
cat > docs/demo-data.csv << 'EOF'
Date,Category,Description,Amount
2025-01-02,Revenue,Product Sale,5000
2025-01-05,Expense,Office Rent,-1200
2025-01-06,Expense,Marketing,-800
2025-01-10,Expense,Salaries,-3000
2025-01-15,Revenue,Product Sale,7000
2025-01-22,Revenue,Service Income,3500
2025-01-25,Expense,Travel,-600
EOF

echo "(Manual exported separately)" > docs/InsightHunter-Manual.pdf

cat > README.md << EOF
# Insight Hunter

🚀 Auto-CFO style financial insights for small businesses.

## Quickstart
\`\`\`bash
chmod +x setup-insight-hunter.sh
./setup-insight-hunter.sh
\`\`\`

- Frontend: http://localhost:3000  
- Backend: http://localhost:4000  

### Demo Account
- Email: demo@insighthunter.com  
- Password: password123

📖 Full manual: docs/InsightHunter-Manual.pdf
EOF

# =========================================
# ⚙️ Backend
# =========================================
cd apps/backend
npm init -y >/dev/null
npm install express cors prisma @prisma/client bcrypt jsonwebtoken body-parser >/dev/null

# Prisma schema
cat > prisma/schema.prisma << EOF
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id         String   @id @default(cuid())
  email      String   @unique
  password   String
  demoMode   Boolean  @default(true)
  resetToken String?
  createdAt  DateTime @default(now())
  updatedAt  DateTime @updatedAt
}
EOF

# Backend index.js
cat > src/index.js << 'EOF'
const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

const app = express();
app.use(cors());
app.use(bodyParser.json());

const JWT_SECRET = process.env.JWT_SECRET || "supersecretjwtkey";

function authenticateToken(req,res,next){
  const token = req.headers["authorization"]?.split(" ")[1];
  if (!token) return res.sendStatus(401);
  jwt.verify(token, JWT_SECRET, (err,user)=>{
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

app.get("/", (req,res)=>res.json({status:"Backend running"}));

app.post("/auth/register", async (req,res)=>{
  const { email, password } = req.body;
  const hashed = await bcrypt.hash(password,10);
  try {
    const user = await prisma.user.create({ data: { email, password: hashed } });
    res.json(user);
  } catch {
    res.status(400).json({error:"User exists"});
  }
});

app.post("/auth/login", async (req,res)=>{
  const { email, password } = req.body;
  const user = await prisma.user.findUnique({where:{email}});
  if (!user) return res.status(400).json({error:"Invalid credentials"});
  const match = await bcrypt.compare(password,user.password);
  if (!match) return res.status(400).json({error:"Invalid credentials"});
  const token = jwt.sign({id:user.id,email:user.email},JWT_SECRET,{expiresIn:"1d"});
  res.json({token,user});
});

app.post("/auth/forgot", async (req,res)=>{
  const { email } = req.body;
  const token = Math.random().toString(36).substring(2);
  try {
    await prisma.user.update({ where:{email}, data:{resetToken:token} });
    res.json({message:"Reset token generated", token});
  } catch {
    res.status(400).json({error:"No such user"});
  }
});

app.post("/auth/reset", async (req,res)=>{
  const { token, password } = req.body;
  const hashed = await bcrypt.hash(password,10);
  const user = await prisma.user.updateMany({
    where:{resetToken:token},
    data:{password:hashed, resetToken:null}
  });
  if (!user.count) return res.status(400).json({error:"Invalid token"});
  res.json({message:"Password reset"});
});

app.patch("/users/:id/demo-mode", authenticateToken, async (req,res)=>{
  const { demoMode } = req.body;
  const { id } = req.params;
  if (req.user.id !== id) return res.sendStatus(403);
  const user = await prisma.user.update({ where: { id }, data: { demoMode } });
  res.json(user);
});

app.get("/reports", authenticateToken, async (req,res)=>{
  res.json({
    insights:[
      "Revenue grew 12% this month",
      "Expenses trending lower than last quarter",
      "Healthy cash flow maintained"
    ]
  });
});

const PORT=4000;
app.listen(PORT,()=>console.log("Backend running on "+PORT));
EOF

# Seed
cat > prisma/seed.js << 'EOF'
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
EOF

# Backend env
cat > .env << EOF
DATABASE_URL=$DB_URL
JWT_SECRET=$JWT_SECRET
EOF

cd ../../..

# =========================================
# ⚡ Workers
# =========================================
cd workers
cat > index.js << 'EOF'
export default {
  async fetch() {
    return new Response("Insight Hunter Worker Active");
  }
}
EOF

cat > .dev.vars << EOF
CLOUDFLARE_API_KEY=$CF_KEY
EOF
cd ..

# =========================================
# 🎨 Frontend (manual scaffold)
# =========================================
cd insight-hunter/apps/frontend

# package.json
cat > package.json << 'EOF'
{
  "name": "frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "axios": "^1.6.7",
    "chart.js": "^4.4.1",
    "react-chartjs-2": "^5.2.0",
    "next": "14.2.4",
    "react": "18.3.1",
    "react-dom": "18.3.1"
  },
  "devDependencies": {
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.3",
    "typescript": "^5.4.5"
  }
}
EOF

# tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom","dom.iterable","esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": false,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true
  },
  "include": ["next-env.d.ts","**/*.ts","**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF

# next.config.js
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {};
module.exports = nextConfig;
EOF

# postcss.config.js
cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# tailwind.config.ts
cat > tailwind.config.ts << 'EOF'
import type { Config } from "tailwindcss";
const config: Config = {
  content: ["./app/**/*.{js,ts,jsx,tsx}","./src/**/*.{js,ts,jsx,tsx}"],
  theme: { extend: { colors: { brand: { DEFAULT: "#ea580c", dark: "#9a3412" } } } },
  plugins: [],
};
export default config;
EOF

# Globals
cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body { @apply bg-gray-100 text-gray-900; }
EOF

# Layout
cat > app/layout.tsx << 'EOF'
import "./globals.css";
import { ReactNode } from "react";

export const metadata = { title: "Insight Hunter", description: "AI-powered financial insights" };

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
EOF

# Components
mkdir -p src/components
cat > src/components/Layout.tsx << 'EOF'
"use client";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function Layout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const handleLogout = () => { localStorage.removeItem("token"); router.push("/login"); };

  return (
    <div className="flex min-h-screen bg-gray-100">
      <aside className="w-64 bg-white shadow-md">
        <div className="p-4 font-bold text-orange-600 text-lg">Insight Hunter</div>
        <nav className="space-y-2 px-4">
          <Link href="/dashboard" className="block hover:text-orange-600">Dashboard</Link>
          <Link href="/reports" className="block hover:text-orange-600">Reports</Link>
          <Link href="/settings" className="block hover:text-orange-600">Settings</Link>
          <button onClick={handleLogout} className="mt-4 w-full text-left text-red-600">Logout</button>
        </nav>
      </aside>
      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}
EOF

cat > src/components/DemoBadge.tsx << 'EOF'
export default function DemoBadge() {
  return <div className="bg-orange-100 border border-orange-600 text-orange-700 px-3 py-1 rounded text-sm mb-4">
    Demo Mode ON – Sample data shown
  </div>;
}
EOF

cat > src/components/Insights.tsx << 'EOF'
interface Props { insights: string[] }
export default function Insights({ insights }: Props) {
  return (
    <div className="mt-4 grid gap-4 md:grid-cols-2">
      {insights.map((insight, i) => (
        <div key={i} className="p-4 bg-white rounded shadow border-l-4 border-orange-600">
          <p className="text-gray-800">{insight}</p>
        </div>
      ))}
    </div>
  );
}
EOF

# Pages
cat > app/page.tsx << 'EOF'
import Link from "next/link";
export default function HomePage() {
  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-orange-500 to-orange-700 text-white">
      <div className="text-center">
        <h1 className="text-4xl font-bold mb-4">Welcome to Insight Hunter</h1>
        <p className="mb-6">Your AI-powered financial insights dashboard</p>
        <Link href="/login" className="px-4 py-2 bg-white text-orange-600 rounded">Get Started</Link>
      </div>
    </div>
  );
}
EOF

cat > app/login.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
export default function LoginPage() {
  const [email,setEmail]=useState(""); const [password,setPassword]=useState("");
  const router = useRouter();
  const handleLogin = async (e:any)=>{
    e.preventDefault();
    const res = await fetch("http://localhost:4000/auth/login",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email,password})});
    const data = await res.json();
    if (data.token){ localStorage.setItem("token",data.token); router.push("/dashboard"); }
    else alert("Login failed");
  };
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form onSubmit={handleLogin} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Login</h1>
        <input type="email" placeholder="Email" className="w-full mb-2 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <input type="password" placeholder="Password" className="w-full mb-4 p-2 border rounded" value={password} onChange={e=>setPassword(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Login</button>
      </form>
    </div>
  );
}
EOF

cat > app/register.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
export default function RegisterPage() {
  const [email,setEmail]=useState(""); const [password,setPassword]=useState("");
  const router = useRouter();
  const handleRegister = async (e:any)=>{
    e.preventDefault();
    await fetch("http://localhost:4000/auth/register",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email,password})});
    router.push("/login");
  };
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form onSubmit={handleRegister} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Register</h1>
        <input type="email" placeholder="Email" className="w-full mb-2 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <input type="password" placeholder="Password" className="w-full mb-4 p-2 border rounded" value={password} onChange={e=>setPassword(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Register</button>
      </form>
    </div>
  );
}
EOF

cat > app/forgot.tsx << 'EOF'
"use client";
import { useState } from "react";
export default function ForgotPage() {
  const [email,setEmail]=useState("");
  const handleSubmit = async (e:any)=>{
    e.preventDefault();
    const res = await fetch("http://localhost:4000/auth/forgot",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({email})});
    const data = await res.json(); alert(data.message || data.error);
  };
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Forgot Password</h1>
        <input type="email" placeholder="Email" className="w-full mb-4 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Send Reset</button>
      </form>
    </div>
  );
}
EOF

cat > app/reset.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
export default function ResetPage() {
  const [token,setToken]=useState(""); const [password,setPassword]=useState("");
  const router = useRouter();
  const handleSubmit = async (e:any)=>{
    e.preventDefault();
    const res = await fetch("http://localhost:4000/auth/reset",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({token,password})});
    const data = await res.json(); alert(data.message || data.error); router.push("/login");
  };
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-100">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-