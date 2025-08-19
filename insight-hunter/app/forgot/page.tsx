"use client";
import { useState } from "react";

export default function ForgotPage() {
  const [email, setEmail] = useState("");
  const [msg, setMsg] = useState("");

  const handleSubmit = async (e:any) => {
    e.preventDefault();
    const res = await fetch("http://localhost:4000/auth/forgot", {
      method:"POST",
      headers:{"Content-Type":"application/json"},
      body:JSON.stringify({email})
    });
    const data = await res.json();
    setMsg(data.message || data.error || "Error");
  };

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-50">
      <form onSubmit={handleSubmit} className="bg-white p-6 rounded shadow-md w-80">
        <h2 className="text-2xl font-bold mb-4 text-orange-600">Forgot Password</h2>
        <input type="email" placeholder="Email" value={email} onChange={e=>setEmail(e.target.value)} className="w-full border p-2 mb-3 rounded"/>
        <button type="submit" className="w-full bg-orange-600 text-white py-2 rounded hover:bg-orange-700">Send Reset</button>
        {msg && <p className="mt-2 text-sm text-gray-600">{msg}</p>}
      </form>
    </div>
  );
}
