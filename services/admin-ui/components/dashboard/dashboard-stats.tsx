"use client";
export function DashboardStats() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <div className="rounded-lg border p-4">Users: 0</div>
      <div className="rounded-lg border p-4">Subscriptions: 0</div>
      <div className="rounded-lg border p-4">Invoices: 0</div>
      <div className="rounded-lg border p-4">Payments: 0</div>
    </div>
  );
}

