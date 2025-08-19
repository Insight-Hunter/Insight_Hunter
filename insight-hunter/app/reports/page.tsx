"use client";
import Layout from "@/components/Layout";
import DemoBadge from "@/components/DemoBadge";
import Insights from "@/components/Insights";
import { Line } from "react-chartjs-2";
import { Chart as ChartJS, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from "chart.js";
import { useEffect, useState } from "react";

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

export default function ReportsPage() {
  const [insights, setInsights] = useState<string[]>([]);

  useEffect(() => {
    setInsights([
      "Top expense category: Salaries",
      "Revenue spike detected mid-month",
      "Travel expenses remain under budget"
    ]);
  }, []);

  const data = {
    labels: ["Week 1", "Week 2", "Week 3", "Week 4"],
    datasets: [
      { label: "Revenue", data: [2000, 3000, 2500, 4000], borderColor: "rgba(249,115,22,1)", fill: false },
      { label: "Expenses", data: [1000, 1500, 1200, 1600], borderColor: "rgba(234,88,12,1)", fill: false }
    ]
  };

  return (
    <Layout>
      <DemoBadge />
      <h1 className="text-2xl font-bold text-orange-600 mb-4">Reports</h1>
      <div className="bg-white p-4 rounded shadow">
        <Line data={data} />
      </div>
      <Insights insights={insights} />
    </Layout>
  );
}
