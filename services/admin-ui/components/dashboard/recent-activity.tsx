"use client";
export function RecentActivity() {
  return (
    <div className="rounded-lg border p-4">
      <div className="font-semibold mb-2">Recent Activity</div>
      <ul className="text-sm text-muted-foreground list-disc pl-5">
        <li>No recent activity</li>
      </ul>
    </div>
  );
}

