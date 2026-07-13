import { useQuery } from '@tanstack/react-query'
import { supabase } from '@/lib/supabase'

export function useAttendance(date?: string, role?: 'member' | 'trainer') {
  return useQuery({
    queryKey: ['attendance', date, role],
    queryFn: async () => {
      let query = supabase
        .from('attendance')
        .select('*, profiles!attendance_member_id_fkey(full_name, email, role, code)')
        .order('check_in_time', { ascending: false })

      if (date) query = query.eq('check_in_date', date)
      if (role) {
        const { data: roleIds } = await supabase
          .from('profiles')
          .select('id')
          .eq('role', role)
        const ids = (roleIds ?? []).map(r => r.id)
        if (ids.length > 0) query = query.in('member_id', ids)
        else query = query.in('member_id', [''])
      }

      const { data } = await query
      const records = data ?? []

      // Pair rows: each session is 2 rows (check-in, check-out).
      // A session with only 1 row means still checked in.
      const grouped: Record<string, any[]> = {}
      for (const r of records) {
        if (!grouped[r.member_id]) grouped[r.member_id] = []
        grouped[r.member_id].push(r)
      }

      const sessions: any[] = []
      for (const [memberId, rows] of Object.entries(grouped)) {
        rows.sort((a, b) => new Date(a.check_in_time).getTime() - new Date(b.check_in_time).getTime())
        for (let i = 0; i < rows.length; i += 2) {
          sessions.push({
            id: rows[i].id,
            member_id: memberId,
            profiles: rows[i].profiles,
            check_in_time: rows[i].check_in_time,
            check_in_date: rows[i].check_in_date,
            check_out_time: rows[i + 1]?.check_in_time ?? null,
          })
        }
      }

      sessions.sort((a, b) => new Date(b.check_in_time).getTime() - new Date(a.check_in_time).getTime())
      return sessions
    },
  })
}
