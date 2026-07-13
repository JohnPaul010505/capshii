import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend, LineChart, Line, AreaChart, Area,
} from 'recharts'

const COLORS = ['#7C3AED', '#22C55E', '#F59E0B', '#EF4444', '#3B82F6', '#C084FC']

export default function ReportsPage() {
  const { data: membershipData } = useQuery({
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

  const { data: genderData } = useQuery({
    queryKey: ['report-gender'],
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

  const { data: growthData } = useQuery({
    queryKey: ['report-growth'],
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

  const { data: attendanceTrend } = useQuery({
    queryKey: ['report-attendance-trend'],
    queryFn: async () => {
      const thirtyDaysAgo = new Date()
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 29)
      const { data } = await supabase
        .from('attendance')
        .select('check_in_date')
        .gte('check_in_date', thirtyDaysAgo.toISOString().split('T')[0])
        .order('check_in_date', { ascending: true })

      const counts: Record<string, number> = {}
      data?.forEach(a => {
        counts[a.check_in_date] = (counts[a.check_in_date] || 0) + 1
      })
      const days = []
      for (let i = 29; i >= 0; i--) {
        const d = new Date()
        d.setDate(d.getDate() - i)
        const key = d.toISOString().split('T')[0]
        days.push({ date: key, checkins: counts[key] || 0 })
      }
      return days
    },
  })

  const totalRevenue = membershipData?.reduce((sum, m) => sum + m.revenue, 0) ?? 0

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-[#ECECFC]">Reports & Analytics</h1>
        <p className="text-[#55557A] text-sm mt-1">Track membership trends, revenue, and member growth</p>
      </div>

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
          <p className="text-sm text-[#55557A]">Total Members</p>
          <p className="text-2xl font-bold text-[#ECECFC] mt-1">
            {growthData && growthData.length > 0 ? growthData[growthData.length - 1].totalMembers : 0}
          </p>
        </div>
        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <p className="text-sm text-[#55557A]">Avg Revenue/Member</p>
          <p className="text-2xl font-bold text-[#C084FC] mt-1">
            ${growthData && growthData.length > 0 && growthData[growthData.length - 1].totalMembers > 0
              ? (totalRevenue / growthData[growthData.length - 1].totalMembers).toFixed(0)
              : '0'}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <h2 className="text-lg font-semibold mb-4 text-[#ECECFC]">Membership Plans</h2>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={membershipData ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2A2A45" />
                <XAxis dataKey="name" tick={{ fill: '#55557A', fontSize: 12 }} />
                <YAxis tick={{ fill: '#55557A', fontSize: 12 }} />
                <Tooltip contentStyle={{ backgroundColor: '#1C1C35', border: '1px solid #2A2A45', borderRadius: '8px', color: '#ECECFC' }} labelStyle={{ color: '#B4B4D0' }} />
                <Bar dataKey="count" fill="url(#reportPurple)" radius={[4, 4, 0, 0]} />
                <defs>
                  <linearGradient id="reportPurple" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#7C3AED" />
                    <stop offset="100%" stopColor="#7C3AED" stopOpacity={0.3} />
                  </linearGradient>
                </defs>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <h2 className="text-lg font-semibold mb-4 text-[#ECECFC]">Revenue by Plan</h2>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={membershipData ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2A2A45" />
                <XAxis dataKey="name" tick={{ fill: '#55557A', fontSize: 12 }} />
                <YAxis tick={{ fill: '#55557A', fontSize: 12 }} tickFormatter={v => `$${v}`} />
                <Tooltip contentStyle={{ backgroundColor: '#1C1C35', border: '1px solid #2A2A45', borderRadius: '8px', color: '#ECECFC' }} labelStyle={{ color: '#B4B4D0' }} formatter={(v: number) => [`$${v}`, 'Revenue']} />
                <Bar dataKey="revenue" fill="url(#revenueGreen)" radius={[4, 4, 0, 0]} />
                <defs>
                  <linearGradient id="revenueGreen" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#22C55E" />
                    <stop offset="100%" stopColor="#22C55E" stopOpacity={0.3} />
                  </linearGradient>
                </defs>
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <h2 className="text-lg font-semibold mb-4 text-[#ECECFC]">Member Growth (30-day)</h2>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={attendanceTrend ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2A2A45" />
                <XAxis dataKey="date" tick={{ fill: '#55557A', fontSize: 12 }} tickFormatter={v => new Date(v).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })} />
                <YAxis tick={{ fill: '#55557A', fontSize: 12 }} />
                <Tooltip contentStyle={{ backgroundColor: '#1C1C35', border: '1px solid #2A2A45', borderRadius: '8px', color: '#ECECFC' }} labelStyle={{ color: '#B4B4D0' }} />
                <Area type="monotone" dataKey="checkins" stroke="#3B82F6" fill="#3B82F6" fillOpacity={0.15} strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <h2 className="text-lg font-semibold mb-4 text-[#ECECFC]">Member Growth Over Time</h2>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={growthData ?? []}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2A2A45" />
                <XAxis dataKey="month" tick={{ fill: '#55557A', fontSize: 12 }} />
                <YAxis tick={{ fill: '#55557A', fontSize: 12 }} />
                <Tooltip contentStyle={{ backgroundColor: '#1C1C35', border: '1px solid #2A2A45', borderRadius: '8px', color: '#ECECFC' }} labelStyle={{ color: '#B4B4D0' }} />
                <Line type="monotone" dataKey="totalMembers" stroke="#7C3AED" strokeWidth={2} dot={{ fill: '#C084FC', r: 3 }} />
                <Line type="monotone" dataKey="newMembers" stroke="#22C55E" strokeWidth={2} dot={{ fill: '#4ADE80', r: 3 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <h2 className="text-lg font-semibold mb-4 text-[#ECECFC]">Gender Distribution</h2>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={genderData ?? []} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={90} innerRadius={50} paddingAngle={3}>
                  {genderData?.map((_, i) => (<Cell key={i} fill={COLORS[i % COLORS.length]} />))}
                </Pie>
                <Tooltip contentStyle={{ backgroundColor: '#1C1C35', border: '1px solid #2A2A45', borderRadius: '8px', color: '#ECECFC' }} />
                <Legend formatter={(value) => <span style={{ color: '#B4B4D0' }}>{value}</span>} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  )
}
