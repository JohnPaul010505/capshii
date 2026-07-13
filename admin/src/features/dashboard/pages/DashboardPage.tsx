import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { Users, Dumbbell, CalendarCheck, TrendingUp, Activity } from 'lucide-react'
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  LineChart, Line, PieChart, Pie, Cell,
} from 'recharts'
import StatsCard from '@/components/StatsCard'
import ChartCard from '@/components/ChartCard'

const COLORS = ['#7C3AED', '#22C55E', '#F59E0B', '#EF4444', '#3B82F6', '#C084FC']
const AXIS_TICK = { fill: '#9494BD', fontSize: 12 }
const TOOLTIP_STYLE = { backgroundColor: '#1C1C35', border: '1px solid #2A2A45', borderRadius: 10, color: '#ECECFC' }

function useDashboardStats() {
  return useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const [members, trainers, attendanceToday] = await Promise.all([
        supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'member'),
        supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'trainer'),
        supabase.from('attendance').select('id', { count: 'exact', head: true }).eq('check_in_date', new Date().toISOString().split('T')[0]),
      ])
      return {
        totalMembers: members.count ?? 0,
        totalTrainers: trainers.count ?? 0,
        attendanceToday: attendanceToday.count ?? 0,
      }
    },
  })
}

const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

function getMonthOptions() {
  const options: { value: string; label: string }[] = []
  const now = new Date()
  for (let y = 2026; y <= now.getFullYear(); y++) {
    const maxM = y === now.getFullYear() ? now.getMonth() : 11
    for (let m = 0; m <= maxM; m++) {
      const d = new Date(y, m, 1)
      const value = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
      options.push({ value, label: `${MONTH_NAMES[d.getMonth()]} ${d.getFullYear()}` })
    }
  }
  return options
}

function useAttendanceChart(yearMonth: string) {
  return useQuery({
    queryKey: ['attendance-chart', yearMonth],
    queryFn: async () => {
      const [year, month] = yearMonth.split('-').map(Number)
      const monthStart = new Date(year, month - 1, 1)
      const monthEnd = new Date(year, month, 0)
      const daysInMonth = monthEnd.getDate()

      const { data } = await supabase
        .from('attendance')
        .select('check_in_date')
        .gte('check_in_date', monthStart.toISOString().split('T')[0])
        .lte('check_in_date', monthEnd.toISOString().split('T')[0])

      const counts: Record<string, number> = {}
      if (data) {
        data.forEach(a => {
          counts[a.check_in_date] = (counts[a.check_in_date] || 0) + 1
        })
      }
      const days = []
      for (let i = 1; i <= daysInMonth; i++) {
        const key = `${year}-${String(month).padStart(2, '0')}-${String(i).padStart(2, '0')}`
        days.push({ date: key, count: counts[key] || 0 })
      }
      return days
    },
  })
}

function useGrowthData() {
  return useQuery({
    queryKey: ['dashboard-growth'],
    queryFn: async () => {
      const { data } = await supabase
        .from('profiles')
        .select('created_at')
        .eq('role', 'member')
        .order('created_at', { ascending: true })

      const monthly: Record<string, number> = {}
      data?.forEach(p => {
        const key = p.created_at?.slice(0, 7)
        if (key) monthly[key] = (monthly[key] || 0) + 1
      })
      let cumulative = 0
      return Object.entries(monthly).map(([month, count]) => {
        cumulative += count
        return { month, newMembers: count, totalMembers: cumulative }
      })
    },
  })
}

function useGenderData() {
  return useQuery({
    queryKey: ['dashboard-gender'],
    queryFn: async () => {
      const { data } = await supabase.from('profiles').select('gender').eq('role', 'member')
      const m = data?.filter(p => p.gender === 'male').length ?? 0
      const f = data?.filter(p => p.gender === 'female').length ?? 0
      const o = data?.filter(p => p.gender && !['male', 'female'].includes(p.gender)).length ?? 0
      return [
        { name: 'Male', value: m },
        { name: 'Female', value: f },
        { name: 'Other', value: o },
      ].filter(d => d.value > 0)
    },
  })
}

export default function DashboardPage() {
  const { data: stats, isLoading } = useDashboardStats()

  const now = new Date()
  const defaultMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
  const [selectedMonth, setSelectedMonth] = useState(defaultMonth)
  const monthOptions = useMemo(() => getMonthOptions(), [])

  const { data: chartData } = useAttendanceChart(selectedMonth)
  const { data: growthData } = useGrowthData()
  const { data: genderData } = useGenderData()

  const genderTotal = useMemo(() => (genderData ?? []).reduce((sum, d) => sum + d.value, 0), [genderData])

  if (isLoading) return <div className="text-center py-8 text-[#55557A]">Loading...</div>

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-[#ECECFC]">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatsCard title="Total Members" value={stats?.totalMembers ?? 0} icon={Users} />
        <StatsCard title="Total Trainers" value={stats?.totalTrainers ?? 0} icon={Dumbbell} />
        <StatsCard title="Attendance Today" value={stats?.attendanceToday ?? 0} icon={CalendarCheck} />
      </div>

      <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-[#ECECFC]">Daily Check-ins</h2>
          <select
            value={selectedMonth}
            onChange={e => setSelectedMonth(e.target.value)}
            className="px-3 py-1.5 bg-[#1C1C35] border border-[#2A2A45] rounded-lg text-sm text-[#ECECFC] focus:outline-none focus:ring-2 focus:ring-[#7C3AED]/50 cursor-pointer"
          >
            {monthOptions.map(m => (
              <option key={m.value} value={m.value} className="bg-[#1C1C35]">{m.label}</option>
            ))}
          </select>
        </div>
        <div className="h-72">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#2A2A45" />
              <XAxis dataKey="date" tick={AXIS_TICK} tickFormatter={v => String(new Date(v).getDate())} />
              <YAxis tick={AXIS_TICK} />
              <Tooltip contentStyle={TOOLTIP_STYLE} labelStyle={{ color: '#B4B4D0' }} labelFormatter={v => new Date(v).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })} />
              <Area type="monotone" dataKey="count" stroke="#3B82F6" fill="#3B82F6" fillOpacity={0.15} strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ChartCard title="Member Growth Over Time" icon={TrendingUp}>
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={growthData ?? []} margin={{ top: 12, right: 8, left: -8, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#2A2A45" vertical={false} />
              <XAxis dataKey="month" tick={AXIS_TICK} axisLine={{ stroke: '#2A2A45' }} tickLine={false} />
              <YAxis tick={AXIS_TICK} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={TOOLTIP_STYLE} labelStyle={{ color: '#B4B4D0' }} />
              <Line type="monotone" dataKey="totalMembers" stroke="#7C3AED" strokeWidth={2} dot={{ fill: '#C084FC', r: 3 }} name="Total" />
              <Line type="monotone" dataKey="newMembers" stroke="#22C55E" strokeWidth={2} dot={{ fill: '#4ADE80', r: 3 }} name="New" />
            </LineChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard title="Gender Distribution" icon={Activity} isEmpty={genderTotal === 0} emptyMessage="No member profile data yet.">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie data={genderData ?? []} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={90} innerRadius={58} paddingAngle={3}>
                {(genderData ?? []).map((_, i) => (<Cell key={i} fill={COLORS[i % COLORS.length]} />))}
              </Pie>
              <Tooltip contentStyle={TOOLTIP_STYLE} />
            </PieChart>
          </ResponsiveContainer>
          <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-2xl font-bold text-[#ECECFC]">{genderTotal}</span>
            <span className="text-xs text-[#8888B3]">members</span>
          </div>
        </ChartCard>
      </div>
    </div>
  )
}
