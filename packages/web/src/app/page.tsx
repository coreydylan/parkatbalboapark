import { ParkMap } from '@/components/map/ParkMap'
import { Sidebar } from '@/components/sidebar/Sidebar'
import { Header } from '@/components/Header'

export default function Home() {
  return (
    <main className="h-screen flex flex-col">
      <Header />
      <div className="flex-1 flex relative overflow-hidden">
        <Sidebar />
        <ParkMap />
      </div>
    </main>
  )
}
