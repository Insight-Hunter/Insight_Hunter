cd insight-hunter/apps/frontend

# ensure app folder exists
mkdir -p app

# layout.tsx
cat > app/layout.tsx << 'EOF'
import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Insight Hunter",
  description: "AI-Powered Financial Insights",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-gray-50 text-gray-900">{children}</body>
    </html>
  );
}
EOF

# globals.css
cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# Landing page
cat > app/page.tsx << 'EOF'
export default function LandingPage() {
  return (
    <main className="flex flex-col items-center justify-center h-screen bg-gradient-to-r from-orange-500 to-orange-700 text-white">
      <h1 className="text-5xl font-bold mb-4">Welcome to Insight Hunter</h1>
      <p className="mb-8">AI-Powered Financial Insights for Small Businesses</p>
      <a href="/login" className="bg-white text-orange-600 px-6 py-2 rounded font-semibold">Get Started</a>
    </main>
  );
}
EOF

# Login
cat > app/login.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [email,setEmail]=useState("");
  const [password,setPassword]=useState("");
  const handleSubmit=async(e:any)=>{
    e.preventDefault();
    const res=await fetch("http://localhost:4000/auth/login",{
      method:"POST",headers:{"Content-Type":"application/json"},
      body:JSON.stringify({email,password})
    });
    if(res.ok){const {token}=await res.json();localStorage.setItem("token",token);router.push("/dashboard");}
    else alert("Login failed");
  };
  return (
    <div className="flex items-center justify-center h-screen bg-gray-100">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Login</h1>
        <input type="email" placeholder="Email" className="w-full mb-2 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <input type="password" placeholder="Password" className="w-full mb-4 p-2 border rounded" value={password} onChange={e=>setPassword(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Login</button>
      </form>
    </div>
  );
}
EOF

# Register
cat > app/register.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";

export default function RegisterPage() {
  const router = useRouter();
  const [email,setEmail]=useState("");
  const [password,setPassword]=useState("");
  const handleSubmit=async(e:any)=>{
    e.preventDefault();
    const res=await fetch("http://localhost:4000/auth/register",{
      method:"POST",headers:{"Content-Type":"application/json"},
      body:JSON.stringify({email,password})
    });
    if(res.ok){alert("Registered! Please login.");router.push("/login");}
    else alert("Registration failed");
  };
  return (
    <div className="flex items-center justify-center h-screen bg-gray-100">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Register</h1>
        <input type="email" placeholder="Email" className="w-full mb-2 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <input type="password" placeholder="Password" className="w-full mb-4 p-2 border rounded" value={password} onChange={e=>setPassword(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Register</button>
      </form>
    </div>
  );
}
EOF