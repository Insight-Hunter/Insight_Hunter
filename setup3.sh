# Forgot Password
cat > app/forgot.tsx << 'EOF'
"use client";
import { useState } from "react";

export default function ForgotPage() {
  const [email,setEmail]=useState("");
  const handleSubmit=async(e:any)=>{
    e.preventDefault();
    await fetch("http://localhost:4000/auth/forgot-password",{
      method:"POST",headers:{"Content-Type":"application/json"},
      body:JSON.stringify({email})
    });
    alert("If this email exists, a reset link has been sent.");
  };
  return (
    <div className="flex items-center justify-center h-screen bg-gray-100">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Forgot Password</h1>
        <input type="email" placeholder="Email" className="w-full mb-4 p-2 border rounded" value={email} onChange={e=>setEmail(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Send Reset Link</button>
      </form>
    </div>
  );
}
EOF

# Reset Password
cat > app/reset.tsx << 'EOF'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";

export default function ResetPage() {
  const router = useRouter();
  const [token,setToken]=useState("");
  const [password,setPassword]=useState("");
  const handleSubmit=async(e:any)=>{
    e.preventDefault();
    await fetch("http://localhost:4000/auth/reset-password",{
      method:"POST",headers:{"Content-Type":"application/json"},
      body:JSON.stringify({token,password})
    });
    alert("Password reset! Please login.");
    router.push("/login");
  };
  return (
    <div className="flex items-center justify-center h-screen bg-gray-100">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-80">
        <h1 className="text-xl font-bold mb-4 text-orange-600">Reset Password</h1>
        <input type="text" placeholder="Reset Token" className="w-full mb-2 p-2 border rounded" value={token} onChange={e=>setToken(e.target.value)} />
        <input type="password" placeholder="New Password" className="w-full mb-4 p-2 border rounded" value={password} onChange={e=>setPassword(e.target.value)} />
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded">Reset</button>
      </form>
    </div>
  );
}
EOF

# Dashboard
cat > app/dashboard.tsx << 'EOF'
"use client";
import { useEffect, useState } from "react";
import Layout from "../src/components/Layout";
import DemoBadge from "../src/components/DemoBadge";
import Insights from "../src/components/Insights";

export default function DashboardPage() {
  const [insights,setInsights]=useState<string[]>([]);
  useEffect(()=>{
    const token = localStorage.getItem("token");
    fetch("http://localhost:4000/reports",{headers:{Authorization:`Bearer ${token}`}})
      .then(r=>r.json()).then(d=>setInsights(d.insights||[]));
  },[]);
  return (
    <Layout>
      <h1 className="text-2xl font-bold mb-4">Dashboard</h1>
      <DemoBadge/>
      <Insights insights={insights}/>
    </Layout>
  );
}
EOF

# Reports
cat > app/reports.tsx << 'EOF'
"use client";
import { useEffect, useState } from "react";
import Layout from "../src/components/Layout";
import { Line } from "react-chartjs-2";
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from "chart.js";
ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

export default function ReportsPage() {
  const [data,setData]=useState<any>(null);
  useEffect(()=>{
    const token = localStorage.getItem("token");
    fetch("http://localhost:4000/reports",{headers:{Authorization:`Bearer ${token}`}})
      .then(r=>r.json()).then(d=>setData(d));
  },[]);
  const chartData = {
    labels:["Jan","Feb","Mar","Apr","May"],
    datasets:[{label:"Revenue", data:[5000,6000,7000,8000,9000], borderColor:"#ea580c"}]
  };
  return (
    <Layout>
      <h1 className="text-2xl font-bold mb-4">Reports</h1>
      {data ? <Line data={chartData}/> : <p>Loading...</p>}
    </Layout>
  );
}
EOF

# Settings
cat > app/settings.tsx << 'EOF'
"use client";
import { useState } from "react";
import Layout from "../src/components/Layout";

export default function SettingsPage() {
  const [demoMode,setDemoMode]=useState(true);
  const toggleDemo = async ()=>{
    const token = localStorage.getItem("token");
    const user = JSON.parse(atob(token.split(".")[1]));
    await fetch(`http://localhost:4000/users/${user.id}/demo-mode`,{
      method:"PATCH",headers:{"Content-Type":"application/json",Authorization:`Bearer ${token}`},
      body:JSON.stringify({demoMode:!demoMode})
    });
    setDemoMode(!demoMode);
  };
  return (
    <Layout>
      <h1 className="text-2xl font-bold mb-4">Settings</h1>
      <button onClick={toggleDemo} className="px-4 py-2 bg-orange-600 text-white rounded">
        Toggle Demo Mode (Currently {demoMode ? "ON" : "OFF"})
      </button>
    </Layout>
  );
}
EOF