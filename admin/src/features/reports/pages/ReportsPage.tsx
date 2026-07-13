import { useState } from 'react'
import type { ReactNode } from 'react'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LabelList,
} from 'recharts'
import { Layers, DollarSign, Inbox, type LucideIcon } from 'lucide-react'
import ReportsAttendancePage from './ReportsAttendancePage'

const AXIS_TICK = { fill: '#9494BD', fontSize: 12 }
const TOOLTIP_STYLE = {
  backgroundColor: '#1C1C35',
  border: '1px solid #2A2A45',
  borderRadius: 10,
  color: '#ECECFC',
  boxShadow: '0 12px 28px rgba(0,0,0,0.35)',
}
const TOOLTIP_LABEL_STYLE = { color: '#B4B4D0', marginBottom: 4, fontWeight: 600 }

function CardBadge({ children }: { children: ReactNode }) {
  return (
    <span className="text-xs font-medium text-[#C084FC] bg-[#7C3AED]/15 px-2.5 py-1 rounded-full whitespace-nowrap shrink-0">
      {children}
    </span>
  )
}

function ChartSkeleton() {
  const heights = [35, 62, 48, 80, 40, 70, 52, 90, 45, 58]
  return (
    <div className="h-full w-full flex items-end gap-2 animate-pulse" aria-hidden="true">
      {heights.map((h, i) => (
        <div key={i} className="flex-1 rounded-t-md bg-[#1F1F3D]" style={{ height: `${h}%` }} />
      ))}
    </div>
  )
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="h-full w-full flex flex-col items-center justify-center gap-2 text-center px-6">
      <span className="flex items-center justify-center w-10 h-10 rounded-full bg-[#1C1C35] text-[#5A5A82]">
        <Inbox className="w-5 h-5" strokeWidth={1.75} />
      </span>
      <p className="text-sm text-[#8888B3]">{message}</p>
    </div>
  )
}

interface ChartCardProps {
  title: string
  icon: LucideIcon
  badge?: ReactNode
  isLoading?: boolean
  isEmpty?: boolean
  emptyMessage?: string
  ariaLabel?: string
  footer?: ReactNode
  children: ReactNode
}

function ChartCard({ title, icon: Icon, badge, isLoading, isEmpty, emptyMessage, ariaLabel, footer, children }: ChartCardProps) {
  const showFooter = footer && !isLoading && !isEmpty
  return (
    <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm transition-colors hover:border-[#38385C]">
      <div className="flex items-start justify-between mb-4 gap-3">
        <div className="flex items-center gap-2.5">
          <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-[#7C3AED]/15 text-[#C084FC] shrink-0">
            <Icon className="w-4 h-4" strokeWidth={2} />
          </span>
          <h2 className="text-lg font-semibold text-[#ECECFC]">{title}</h2>
        </div>
        {badge}
      </div>
      <div className="h-72 relative" role="img" aria-label={ariaLabel ?? title}>
        {isLoading ? <ChartSkeleton /> : isEmpty ? <EmptyState message={emptyMessage ?? 'No data yet'} /> : children}
      </div>
      {showFooter ? <div className="mt-4 pt-4 border-t border-[#2A2A45]">{footer}</div> : null}
    </div>
  )
}

export default function ReportsPage() {
  const [activeTab, setActiveTab] = useState<'analytics' | 'attendance'>('analytics')

  const { data: membershipData, isLoading: membershipLoading } = useQuery({
    queryKey: ['report-memberships'],
    queryFn: async () => {
      const { data } = await supabase.from('memberships').select('plan_name, price')
      const planMap: Record<string, { count: number; revenue: number }> = {}
      data?.forEach(m => {
        if (!planMap[m.plan_name]) planMap[m.plan_name] = { count: 0, revenue: 0 }
        planMap[m.plan_name].count++
        planMap[m.plan_name].revenue += Number(m.price)
      })
      return Object.entries(planMap).map(([name, v]) => ({ name, count: v.count, revenue: v.revenue }))
    },
  })

  const totalRevenue = membershipData?.reduce((sum, m) => sum + m.revenue, 0) ?? 0

  const topRevenuePlan = membershipData
    ? membershipData.reduce((max, m) => (m.revenue > max.revenue ? m : max), membershipData[0])
    : null

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#ECECFC]">Reports & Analytics</h1>
          <p className="text-[#55557A] text-sm mt-1">Track membership trends, revenue, and member growth</p>
        </div>
      </div>

      <div className="flex gap-2">
        <button
          onClick={() => setActiveTab('analytics')}
          className={`px-4 py-1.5 text-sm rounded-lg font-medium transition-colors ${
            activeTab === 'analytics'
              ? 'bg-[#7C3AED] text-white'
              : 'bg-[#1C1C35] text-[#B4B4D0] hover:bg-[#242445]'
          }`}
        >
          Analytics
        </button>
        <button
          onClick={() => setActiveTab('attendance')}
          className={`px-4 py-1.5 text-sm rounded-lg font-medium transition-colors ${
            activeTab === 'attendance'
              ? 'bg-[#7C3AED] text-white'
              : 'bg-[#1C1C35] text-[#B4B4D0] hover:bg-[#242445]'
          }`}
        >
          Attendance
        </button>
      </div>

      {activeTab === 'attendance' ? (
        <ReportsAttendancePage />
      ) : (
        <>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
              <p className="text-sm text-[#55557A]">Total Plans</p>
              <p className="text-2xl font-bold text-[#ECECFC] mt-1">{membershipData?.length ?? 0}</p>
            </div>
            <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
              <p className="text-sm text-[#55557A]">Total Revenue</p>
              <p className="text-2xl font-bold text-[#22C55E] mt-1">${totalRevenue.toLocaleString()}</p>
            </div>
            <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
              <p className="text-sm text-[#55557A]">Active Members</p>
              <p className="text-2xl font-bold text-[#C084FC] mt-1">{topRevenuePlan?.name ?? '—'}</p>
            </div>
            <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
              <p className="text-sm text-[#55557A]">Top Plan</p>
              <p className="text-2xl font-bold text-[#F59E0B] mt-1">{topRevenuePlan?.name ?? '—'}</p>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <ChartCard
              title="Membership Plans"
              icon={Layers}
              isLoading={membershipLoading}
              isEmpty={!membershipLoading && (membershipData?.length ?? 0) === 0}
              emptyMessage="No membership plans yet. Add a plan to see it charted here."
              ariaLabel="Bar chart of member count per membership plan"
              badge={<CardBadge>{membershipData?.length ?? 0} plans</CardBadge>}
            >
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={membershipData ?? []} margin={{ top: 24, right: 8, left: -8, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#2A2A45" vertical={false} />
                  <XAxis dataKey="name" tick={AXIS_TICK} axisLine={{ stroke: '#2A2A45' }} tickLine={false} />
                  <YAxis tick={AXIS_TICK} axisLine={false} tickLine={false} allowDecimals={false} />
                  <Tooltip
                    contentStyle={TOOLTIP_STYLE}
                    labelStyle={TOOLTIP_LABEL_STYLE}
                    cursor={{ fill: 'rgba(124,58,237,0.06)' }}
                    formatter={(v: number) => [`${v} members`, 'Count']}
                  />
                  <Bar dataKey="count" fill="url(#reportPurple)" radius={[6, 6, 0, 0]} maxBarSize={56}>
                    <LabelList dataKey="count" position="top" style={{ fill: '#C4B5FD', fontSize: 12, fontWeight: 600 }} />
                  </Bar>
                  <defs>
                    <linearGradient id="reportPurple" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#7C3AED" />
                      <stop offset="100%" stopColor="#7C3AED" stopOpacity={0.35} />
                    </linearGradient>
                  </defs>
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>

            <ChartCard
              title="Revenue by Plan"
              icon={DollarSign}
              isLoading={membershipLoading}
              isEmpty={!membershipLoading && (membershipData?.length ?? 0) === 0}
              emptyMessage="No revenue recorded yet."
              ariaLabel="Bar chart of revenue per membership plan"
              badge={topRevenuePlan ? <CardBadge>Top: {topRevenuePlan.name}</CardBadge> : undefined}
            >
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={membershipData ?? []} margin={{ top: 24, right: 8, left: -8, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#2A2A45" vertical={false} />
                  <XAxis dataKey="name" tick={AXIS_TICK} axisLine={{ stroke: '#2A2A45' }} tickLine={false} />
                  <YAxis tick={AXIS_TICK} axisLine={false} tickLine={false} tickFormatter={v => `$${v}`} />
                  <Tooltip
                    contentStyle={TOOLTIP_STYLE}
                    labelStyle={TOOLTIP_LABEL_STYLE}
                    cursor={{ fill: 'rgba(34,197,94,0.06)' }}
                    formatter={(v: number) => [`$${Number(v).toLocaleString()}`, 'Revenue']}
                  />
                  <Bar dataKey="revenue" fill="url(#revenueGreen)" radius={[6, 6, 0, 0]} maxBarSize={56}>
                    <LabelList
                      dataKey="revenue"
                      position="top"
                      formatter={(v: number) => `$${Number(v).toLocaleString()}`}
                      style={{ fill: '#86EFAC', fontSize: 12, fontWeight: 600 }}
                    />
                  </Bar>
                  <defs>
                    <linearGradient id="revenueGreen" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#22C55E" />
                      <stop offset="100%" stopColor="#22C55E" stopOpacity={0.35} />
                    </linearGradient>
                  </defs>
                </BarChart>
              </ResponsiveContainer>
            </ChartCard>
          </div>
        </>
      )}
    </div>
  )
}
