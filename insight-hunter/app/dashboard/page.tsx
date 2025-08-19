"use client";
import Layout from "@/components/Layout";
import DemoBadge from "@/components/DemoBadge";
import Insights from "@/components/Insights";
import { Bar } from "react-chartjs-2";
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from "chart.js";
import { useEffect, useState } from "react";

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

export default function DashboardPage() {
  const [insights, setInsights] = useState<string[]>([]);

  useEffect(() => {
    setInsights([
      "Revenue grew 12% this month",
      "Expenses are trending lower than last quarter",
      "Healthy cash flow maintained"
    ]);
  }, []);

  const data = {
    labels: ["Jan", "Feb", "Mar", "Apr"],
    datasets: [
      { label: "Revenue", data: [5000, 7000, 6500, 8000], backgroundColor: "rgba(249,115,22,0.8)" },
      { label: "Expenses", data: [3000, 3200, 2800, 3500], backgroundColor: "rgba(234,88,12,0.8)" }
    ]
  };

  return (
    <Layout>
      <DemoBadge />
      <h1 className="text-2xl font-bold text-orange-600 mb-4">Dashboard</h1>
      <div className="bg-white p-4 rounded shadow">
        <Bar data={data} />
      </div>
      <Insights insights={insights} />
    </Layout>
  );
}
