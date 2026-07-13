import { useParams, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'
import { ArrowLeft, Mail, Phone, Users } from 'lucide-react'

export default function TrainerDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()

  const { data: trainer } = useQuery({
    queryKey: ['trainer', id],
    queryFn: async () => {
      const { data } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', id)
        .eq('role', 'trainer')
        .single()
      return data
    },
  })

  const { data: assignedMembers } = useQuery({
    queryKey: ['trainer-members', id],
    queryFn: async () => {
      const { data } = await supabase
        .from('trainer_assignments')
        .select('*, profiles!trainer_assignments_member_id_fkey(full_name, email, phone)')
        .eq('trainer_id', id)
        .eq('status', 'active')
      return data ?? []
    },
  })

  const { data: recentFeedback } = useQuery({
    queryKey: ['trainer-feedback', id],
    queryFn: async () => {
      const { data } = await supabase
        .from('trainer_feedback')
        .select('*, profiles!trainer_feedback_member_id_fkey(full_name)')
        .eq('trainer_id', id)
        .order('created_at', { ascending: false })
        .limit(10)
      return data ?? []
    },
  })

  if (!trainer) {
    return <div className="text-center py-8 text-[#55557A]">Trainer not found</div>
  }

  return (
    <div className="space-y-6">
      <button onClick={() => navigate('/trainers')} className="flex items-center gap-1 text-sm text-[#55557A] hover:text-[#B4B4D0]">
        <ArrowLeft className="w-4 h-4" /> Back to Trainers
      </button>

      <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#22C55E]/30 to-[#4ADE80]/30 flex items-center justify-center">
            <span className="text-2xl font-bold text-[#4ADE80]">{trainer.full_name.charAt(0)}</span>
          </div>
          <div>
            <h1 className="text-xl font-bold text-[#ECECFC]">{trainer.full_name}</h1>
            <p className="text-sm text-[#B4B4D0]">{trainer.email}</p>
            <p className="text-xs font-mono text-[#7C3AED] mt-1">{trainer.code}</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <div className="flex items-center gap-2 text-sm text-[#55557A] mb-1">
            <Mail className="w-4 h-4" />
            <span>Email</span>
          </div>
          <p className="text-sm text-[#ECECFC]">{trainer.email}</p>
        </div>
        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <div className="flex items-center gap-2 text-sm text-[#55557A] mb-1">
            <Phone className="w-4 h-4" />
            <span>Phone</span>
          </div>
          <p className="text-sm text-[#ECECFC]">{trainer.phone || '—'}</p>
        </div>
        <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
          <div className="flex items-center gap-2 text-sm text-[#55557A] mb-1">
            <Users className="w-4 h-4" />
            <span>Assigned Members</span>
          </div>
          <p className="text-2xl font-bold text-[#ECECFC]">{assignedMembers?.length ?? 0}</p>
        </div>
      </div>

      <div className="bg-[#14142A] rounded-xl border border-[#2A2A45] shadow-sm overflow-hidden">
        <div className="px-4 py-3 border-b border-[#2A2A45]">
          <h2 className="font-semibold text-[#ECECFC]">Assigned Members</h2>
        </div>
        {assignedMembers?.length === 0 ? (
          <div className="text-center py-8 text-[#55557A]">No members assigned</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-[#2A2A45] bg-[#0D0D1A]/50">
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Name</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Email</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Phone</th>
              </tr>
            </thead>
            <tbody>
              {assignedMembers?.map(a => (
                <tr key={a.id} className="border-b border-[#2A2A45]/50 last:border-0 hover:bg-[#7C3AED]/5 transition-colors">
                  <td className="px-4 py-3 text-sm font-medium text-[#ECECFC]">{a.profiles?.full_name}</td>
                  <td className="px-4 py-3 text-sm text-[#B4B4D0]">{a.profiles?.email}</td>
                  <td className="px-4 py-3 text-sm text-[#B4B4D0]">{a.profiles?.phone || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <div className="bg-[#14142A] rounded-xl border border-[#2A2A45] shadow-sm overflow-hidden">
        <div className="px-4 py-3 border-b border-[#2A2A45]">
          <h2 className="font-semibold text-[#ECECFC]">Recent Feedback</h2>
        </div>
        {recentFeedback?.length === 0 ? (
          <div className="text-center py-8 text-[#55557A]">No feedback yet</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-[#2A2A45] bg-[#0D0D1A]/50">
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Member</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Feedback</th>
                <th className="text-left px-4 py-3 text-sm font-medium text-[#55557A]">Date</th>
              </tr>
            </thead>
            <tbody>
              {recentFeedback?.map(f => (
                <tr key={f.id} className="border-b border-[#2A2A45]/50 last:border-0 hover:bg-[#7C3AED]/5 transition-colors">
                  <td className="px-4 py-3 text-sm font-medium text-[#ECECFC]">{f.profiles?.full_name}</td>
                  <td className="px-4 py-3 text-sm text-[#B4B4D0] max-w-md truncate">{f.content}</td>
                  <td className="px-4 py-3 text-sm text-[#55557A]">{new Date(f.created_at).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
