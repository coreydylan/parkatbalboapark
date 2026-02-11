import { NextResponse } from 'next/server'
import { readFile } from 'fs/promises'
import { join } from 'path'

export async function GET() {
  const specPath = join(process.cwd(), '..', 'chatgpt', 'openapi.yaml')
  const yaml = await readFile(specPath, 'utf-8')

  return new NextResponse(yaml, {
    headers: {
      'Content-Type': 'text/yaml',
      'Cache-Control': 'public, max-age=3600',
    },
  })
}
