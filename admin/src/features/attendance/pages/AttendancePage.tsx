import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { useAttendance } from '../hooks/useAttendance'
import { Plus, LogOut, LogIn, X } from 'lucide-react'

export default function AttendancePage() {
  const today = new Date().toISOString().split('T')[0]
  const [date, setDate] = useState(today)
  const [role, setRole] = useState<'member' | 'trainer'>('member')
  const [showModal, setShowModal] = useState(false)
  const { data: sessions, isLoading } = useAttendance(date, role)
  const queryClient = useQueryClient()

  const { data: people } = useQuery({
    queryKey: ['attendance-people', role],
    enabled: showModal,
    queryFn: async () => {
      const { data } = await supabase
        .from('profiles')
        .select('id, full_name, email, code')
        .eq('role', role)
        .order('full_name')
      return data ?? []
    },
  })

  const checkinMutation = useMutation({
    mutationFn: async (memberId: string) => {
      const { count } = await supabase
        .from('attendance')
        .select('id', { count: 'exact', head: true })
        .eq('member_id', memberId)
        .eq('check_in_date', today)
      if (count !== null && count % 2 === 1) throw new Error('Already checked in')
      const { error } = await supabase.from('attendance').insert({
        member_id: memberId,
        check_in_time: new Date().toISOString(),
        check_in_date: today,
      })
      if (error) throw error
    },
    onSuccess: () => {
      setShowModal(false)
      queryClient.invalidateQueries({ queryKey: ['attendance'] })
    },
  })

  const checkoutMutation = useMutation({
    mutationFn: async (memberId: string) => {
      const { error } = await supabase.from('attendance').insert({
        member_id: memberId,
        check_in_time: new Date().toISOString(),
        check_in_date: today,
      })
      if (error) throw error
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['attendance'] })
    },
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-[#ECECFC]">Attendance</h1>
        <input
          type="date"
          value={date}
          onChange={e => setDate(e.target.value)}
          className="px-3 py-2 bg-[#1C1C35] border border-[#2A2A45] rounded-lg text-sm text-[#ECECFC] focus:outline-none focus:ring-2 focus:ring-[#7C3AED]/50"
        />
      </div>

      <div className="flex items-center justify-between">
        <div className="flex gap-2">
          <button
            onClick={() => setRole('member')}
            className={`px-4 py-1.5 text-sm rounded-lg font-medium transition-colors ${
              role === 'member'
                ? 'bg-[#7C3AED] text-white'
                : 'bg-[#1C1C35] text-[#B4B4D0] hover:bg-[#242445]'
            }`}
          >
            Members
          </button>
          <button
            onClick={() => setRole('trainer')}
            className={`px-4 py-1.5 text-sm rounded-lg font-medium transition-colors ${
              role === 'trainer'
                ? 'bg-[#7C3AED] text-white'
                : 'bg-[#1C1C35] text-[#B4B4D0] hover:bg-[#242445]'
            }`}
          >
            Trainers
          </button>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-1 px-3 py-1.5 text-sm bg-[#7C3AED] text-white rounded-lg hover:bg-[#6D28D9]"
        >
          <Plus className="w-4 h-4" /> Check In
        </button>
      </div>

      {isLoading ? (
        <div className="text-center py-8 text-[#55557A]">Loading...</div>
      ) : (
        <div className="bg-[#14142A] rounded-xl border border-[#2A2A45] shadow-sm overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="border-b border-[#2A2A45] bg-[#0D0D1A]/50">
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Name</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Role</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Check-in</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Check-out</th>
                <th className="text-center px-4 py-3 text-sm font-medium text-[#55557A]">Actions</th>
              </tr>
            </thead>
            <tbody>
              {sessions?.map(s => (
                <tr key={s.id} className="border-b border-[#2A2A45]/50 last:border-0 hover:bg-[#7C3AED]/5">
                  <td className="px-4 py-3 text-sm font-medium text-[#ECECFC]">
                    {s.profiles?.full_name}
                    <span className="ml-2 text-xs font-mono text-[#7C3AED]">{s.profiles?.code}</span>
                  </td>
                  <td className="px-4 py-3 text-sm text-[#B4B4D0] capitalize">{s.profiles?.role || 'member'}</td>
                  <td className="px-4 py-3 text-sm">
                    <span className="inline-flex items-center gap-1 text-[#4ADE80]">
                      <LogIn className="w-3 h-3" />
                      {new Date(s.check_in_time).toLocaleTimeString()}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm">
                    {s.check_out_time ? (
                      <span className="inline-flex items-center gap-1 text-[#B4B4D0]">
                        <LogOut className="w-3 h-3" />
                        {new Date(s.check_out_time).toLocaleTimeString()}
                      </span>
                    ) : (
                      <span className="text-[#FBBF24] text-xs font-medium">Active</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-center">
                    {!s.check_out_time && (
                      <button
                        onClick={() => checkoutMutation.mutate(s.member_id)}
                        disabled={checkoutMutation.isPending}
                        className="px-3 py-1 text-xs bg-[#F59E0B]/15 text-[#FBBF24] rounded-lg hover:bg-[#F59E0B]/25 disabled:opacity-50"
                      >
                        Check Out
                      </button>
                    )}
                  </td>
                </tr>
              ))}
              {sessions?.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-8 text-center text-[#55557A]">No attendance records</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {showModal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50" onClick={() => setShowModal(false)}>
          <div className="bg-[#14142A] rounded-xl shadow-xl max-w-lg w-full mx-4 max-h-[80vh] flex flex-col border border-[#2A2A45]" onClick={e => e.stopPropagation()}>
            <div className="px-6 py-4 border-b border-[#2A2A45] flex items-center justify-between">
              <h2 className="text-lg font-semibold text-[#ECECFC]">Select {role === 'member' ? 'Member' : 'Trainer'}</h2>
              <button onClick={() => setShowModal(false)} className="text-[#55557A] hover:text-[#B4B4D0]">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="px-6 py-4 flex-1 overflow-y-auto space-y-2">
              {people?.length === 0 ? (
                <p className="text-[#55557A] text-center py-8">No {role}s found</p>
              ) : (
                people?.map(p => (
                  <button
                    key={p.id}
                    onClick={() => checkinMutation.mutate(p.id)}
                    disabled={checkinMutation.isPending}
                    className="w-full flex items-center justify-between p-3 rounded-lg border border-[#2A2A45] hover:bg-[#7C3AED]/10 cursor-pointer disabled:opacity-50 text-left transition-colors"
                  >
                    <div>
                      <p className="font-medium text-sm text-[#ECECFC]">{p.full_name}</p>
                      <p className="text-xs text-[#55557A]">{p.code} — {p.email}</p>
                    </div>
                    <LogIn className="w-4 h-4 text-[#4ADE80] shrink-0" />
                  </button>
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
