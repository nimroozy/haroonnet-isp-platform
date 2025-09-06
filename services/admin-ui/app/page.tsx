import { redirect } from 'next/navigation';
import { DashboardStats } from '@/components/dashboard/dashboard-stats';
import { RecentActivity } from '@/components/dashboard/recent-activity';
import { UsageChart } from '@/components/dashboard/usage-chart';
import { OnlineUsers } from '@/components/dashboard/online-users';

export default function HomePage() {
  // In a real app, you'd check authentication here
  // For now, redirect to login or show dashboard

  return (
    <div className="flex-1 space-y-4 p-4 md:p-8 pt-6">
      <div className="flex items-center justify-between space-y-2">
        <h2 className="text-3xl font-bold tracking-tight">Dashboard</h2>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <DashboardStats />
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <div className="col-span-4">
          <UsageChart />
        </div>
        <div className="col-span-3">
          <OnlineUsers />
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-7">
        <div className="col-span-4">
          <RecentActivity />
        </div>
      </div>
    </div>
  );
}
