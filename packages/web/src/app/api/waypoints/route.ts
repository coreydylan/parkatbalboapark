import { NextRequest, NextResponse } from 'next/server'
import { readFileSync } from 'fs'
import { join } from 'path'

interface RawWaypoint {
  id: number
  osmType: string
  name: string | null
  category: string
  lat: number
  lng: number
  onOfficialMap: boolean
  mapGridRef?: string
  tags: Record<string, string>
}

let cachedWaypoints: RawWaypoint[] | null = null

function loadWaypoints(): RawWaypoint[] {
  if (cachedWaypoints) return cachedWaypoints

  // Try monorepo root first (Vercel), then relative from web package (local dev)
  const paths = [
    join(process.cwd(), 'data', 'raw', 'waypoints.json'),
    join(process.cwd(), '..', '..', 'data', 'raw', 'waypoints.json'),
  ]
  for (const p of paths) {
    try {
      cachedWaypoints = JSON.parse(readFileSync(p, 'utf-8'))
      return cachedWaypoints!
    } catch {
      continue
    }
  }
  return []
}

export async function GET(request: NextRequest) {
  const q = request.nextUrl.searchParams.get('q')?.toLowerCase() ?? ''

  const raw = loadWaypoints()

  // Filter to named waypoints only
  let waypoints = raw.filter((w) => w.name && w.name.trim().length > 0)

  // Apply search filter if provided
  if (q) {
    waypoints = waypoints.filter((w) =>
      w.name!.toLowerCase().includes(q)
    )
  }

  // Sort: onOfficialMap first, then alphabetically
  waypoints.sort((a, b) => {
    if (a.onOfficialMap !== b.onOfficialMap) return a.onOfficialMap ? -1 : 1
    return a.name!.localeCompare(b.name!)
  })

  const transformed = waypoints.map((w) => ({
    id: `${w.osmType}/${w.id}`,
    name: w.name!,
    category: w.category,
    lat: w.lat,
    lng: w.lng,
    onOfficialMap: w.onOfficialMap,
  }))

  return NextResponse.json({ waypoints: transformed })
}
