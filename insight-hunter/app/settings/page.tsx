"use client";
import Layout from "@/components/Layout";
import { useState } from "react";

export default function SettingsPage() {
  const [demoMode, setDemoMode] = useState(true);

  const toggleDemo = () => {
    setDemoMode(!demoMode);
    // TODO: Call backend PATCH /users/:id/demo-mode
  };

  return (
    <Layout>
      <h1 className="text-2xl font-bold text-orange-600 mb-4">Settings</h1>
      <div className="bg-white p-4 rounded shadow">
        <label className="flex items-center space-x-2">
          <input type="checkbox" checked={demoMode} onChange={toggleDemo} />
          <span>Enable Demo Mode</span>
        </label>
      </div>
    </Layout>
  );
}
