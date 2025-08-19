"use client";
import Link from "next/link";
import { useEffect } from "react";
import { useRouter } from "next/navigation";

export default function Landing() {
  const router = useRouter();
  useEffect(() => {
    const token = localStorage.getItem("token");
    if (token) router.push("/dashboard");
  }, [router]);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50 text-center">
      <h1 className="text-4xl font-bold text-orange-600">Insight Hunter</h1>
      <p className="mt-2 text-gray-600">Financial Insights Made Simple</p>
      <div className="mt-6 space-x-4">
        <Link href="/login" className="px-4 py-2 bg-orange-600 text-white rounded hover:bg-orange-700">Login</Link>
        <Link href="/register" className="px-4 py-2 border border-orange-600 text-orange-600 rounded hover:bg-orange-50">Register</Link>
      </div>
    </div>
  );
}
