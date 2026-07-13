import { type LucideIcon } from 'lucide-react'

interface StatsCardProps {
  title: string
  value: number
  icon: LucideIcon
}

export default function StatsCard({ title, value, icon: Icon }: StatsCardProps) {
  return (
    <div className="bg-[#14142A] p-6 rounded-xl border border-[#2A2A45] shadow-sm">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-[#55557A]">{title}</p>
          <p className="text-2xl font-bold mt-1 text-[#ECECFC]">{value.toLocaleString()}</p>
        </div>
        <div className="w-10 h-10 bg-[#7C3AED]/20 rounded-lg flex items-center justify-center">
          <Icon className="w-5 h-5 text-[#C084FC]" />
        </div>
      </div>
    </div>
  )
}
