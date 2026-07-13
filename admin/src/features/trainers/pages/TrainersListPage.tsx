import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQueryClient } from '@tanstack/react-query'
import { useTrainers } from '../hooks/useTrainers'
import { Trash2 } from 'lucide-react'

export default function TrainersListPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { data: trainers, isLoading } = useTrainers()
  const [showModal, setShowModal] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [fullName, setFullName] = useState('')
  const [phone, setPhone] = useState('')
  const [saving, setSaving] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<any>(null)
  const [deleting, setDeleting] = useState(false)

  const handleCreate = async () => {
    if (!email || !password || !fullName) return
    setSaving(true)
    try {
      const res = await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, fullName, role: 'trainer', phone: phone || undefined }),
      })
      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.error || 'Failed to create trainer')
      }
      setShowModal(false)
      setEmail('')
      setPassword('')
      setFullName('')
      setPhone('')
      queryClient.invalidateQueries({ queryKey: ['trainers'] })
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to create trainer')
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      const res = await fetch('/api/delete-user', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: deleteTarget.id }),
      })
      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.error || 'Failed to delete trainer')
      }
      setDeleteTarget(null)
      queryClient.invalidateQueries({ queryKey: ['trainers'] })
    } catch (err) {
      alert(err instanceof Error ? err.message : 'Failed to delete')
    } finally {
      setDeleting(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-[#ECECFC]">Trainers</h1>
        <button onClick={() => setShowModal(true)}
          className="px-4 py-2 bg-[#7C3AED] text-white rounded-lg hover:bg-[#6D28D9] text-sm">
          + Create Trainer
        </button>
      </div>

      {isLoading ? (
        <div className="text-center py-8 text-[#55557A]">Loading...</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {trainers?.map(trainer => (
            <div
              key={trainer.id}
              className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm hover:border-[#7C3AED]/30 cursor-pointer transition-all duration-200 relative group"
              onClick={() => navigate(`/trainers/${trainer.id}`)}
            >
              <button
                onClick={e => { e.stopPropagation(); setDeleteTarget(trainer) }}
                className="absolute top-3 right-3 p-1.5 text-[#55557A] hover:text-[#EF4444] opacity-0 group-hover:opacity-100 transition-opacity"
                title="Delete"
              >
                <Trash2 className="w-4 h-4" />
              </button>
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#22C55E]/30 to-[#4ADE80]/30 flex items-center justify-center">
                  <span className="text-lg font-bold text-[#4ADE80]">{trainer.full_name.charAt(0)}</span>
                </div>
                <div>
                  <p className="font-semibold text-[#ECECFC]">{trainer.full_name}</p>
                  <p className="text-xs font-mono text-[#7C3AED] mt-0.5">{trainer.code}</p>
                  <p className="text-sm text-[#B4B4D0] mt-0.5">{trainer.email}</p>
                </div>
              </div>
            </div>
          ))}
          {trainers?.length === 0 && (
            <p className="text-[#55557A] col-span-full text-center py-8">No trainers found</p>
          )}
        </div>
      )}

      {showModal && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50" onClick={() => setShowModal(false)}>
          <div className="bg-[#14142A] rounded-xl shadow-xl max-w-md w-full mx-4 border border-[#2A2A45]" onClick={e => e.stopPropagation()}>
            <div className="px-6 py-4 border-b border-[#2A2A45]">
              <h2 className="text-lg font-semibold text-[#ECECFC]">Create Trainer Account</h2>
            </div>
            <div className="px-6 py-4 space-y-4">
              <div>
                <label className="block text-sm font-medium text-[#B4B4D0] mb-1">Full Name *</label>
                <input value={fullName} onChange={e => setFullName(e.target.value)}
                  className="w-full px-3 py-2 bg-[#1C1C35] border border-[#2A2A45] rounded-lg text-sm text-[#ECECFC] focus:outline-none focus:ring-2 focus:ring-[#7C3AED]/50" />
              </div>
              <div>
                <label className="block text-sm font-medium text-[#B4B4D0] mb-1">Email *</label>
                <input value={email} onChange={e => setEmail(e.target.value)}
                  className="w-full px-3 py-2 bg-[#1C1C35] border border-[#2A2A45] rounded-lg text-sm text-[#ECECFC] focus:outline-none focus:ring-2 focus:ring-[#7C3AED]/50" type="email" />
              </div>
              <div>
                <label className="block text-sm font-medium text-[#B4B4D0] mb-1">Password *</label>
                <input value={password} onChange={e => setPassword(e.target.value)}
                  className="w-full px-3 py-2 bg-[#1C1C35] border border-[#2A2A45] rounded-lg text-sm text-[#ECECFC] focus:outline-none focus:ring-2 focus:ring-[#7C3AED]/50" type="password" />
              </div>
              <div>
                <label className="block text-sm font-medium text-[#B4B4D0] mb-1">Phone</label>
                <input value={phone} onChange={e => setPhone(e.target.value)}
                  className="w-full px-3 py-2 bg-[#1C1C35] border border-[#2A2A45] rounded-lg text-sm text-[#ECECFC] focus:outline-none focus:ring-2 focus:ring-[#7C3AED]/50" />
              </div>
            </div>
            <div className="px-6 py-4 border-t border-[#2A2A45] flex justify-end gap-3">
              <button onClick={() => setShowModal(false)}
                className="px-4 py-2 text-sm border border-[#2A2A45] rounded-lg text-[#B4B4D0] hover:bg-[#1C1C35]">Cancel</button>
              <button onClick={handleCreate} disabled={saving || !fullName || !email || !password}
                className="px-4 py-2 text-sm bg-[#7C3AED] text-white rounded-lg hover:bg-[#6D28D9] disabled:opacity-50">
                {saving ? 'Creating...' : 'Create Trainer'}
              </button>
            </div>
          </div>
        </div>
      )}

      {deleteTarget && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50" onClick={() => setDeleteTarget(null)}>
          <div className="bg-[#14142A] rounded-xl shadow-xl max-w-sm w-full mx-4 p-6 border border-[#2A2A45]" onClick={e => e.stopPropagation()}>
            <h2 className="text-lg font-bold text-[#ECECFC] mb-2">Delete Trainer?</h2>
            <p className="text-sm text-[#B4B4D0] mb-4">
              This will permanently delete <strong className="text-[#ECECFC]">{deleteTarget.full_name}</strong>'s account and all access.
            </p>
            <div className="flex justify-end gap-3">
              <button onClick={() => setDeleteTarget(null)}
                className="px-4 py-2 text-sm border border-[#2A2A45] rounded-lg text-[#B4B4D0] hover:bg-[#1C1C35]">Cancel</button>
              <button onClick={handleDelete} disabled={deleting}
                className="px-4 py-2 text-sm bg-[#EF4444] text-white rounded-lg hover:bg-[#DC2626] disabled:opacity-50">
                {deleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
