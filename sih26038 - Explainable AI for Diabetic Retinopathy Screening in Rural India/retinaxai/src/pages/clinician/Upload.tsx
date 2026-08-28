import { useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { UploadCloud, Image as ImageIcon, Sparkles, Loader2 } from 'lucide-react'
import { AppShell } from '@/components/shared/AppShell'
import { Card, CardContent } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { useScreenings } from '@/context/ScreeningsContext'

const ACCEPTED = ['image/jpeg', 'image/png', 'image/tiff']

export default function Upload() {
  const navigate = useNavigate()
  const { addScreeningFromFile, addScreeningFromSample } = useScreenings()
  const [file, setFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [dragActive, setDragActive] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  function handleFile(f: File | undefined | null) {
    if (!f) return
    if (!ACCEPTED.includes(f.type) && !f.name.match(/\.(jpe?g|png|tiff?)$/i)) {
      setError('Unsupported file type. Please upload JPG, PNG, or TIFF.')
      return
    }
    if (f.size > 10 * 1024 * 1024) {
      setError('File exceeds the 10MB limit.')
      return
    }
    setError(null)
    setFile(f)
    setPreviewUrl(URL.createObjectURL(f))
  }

  async function handleAnalyze() {
    if (!file) return
    setSubmitting(true)
    try {
      const result = await addScreeningFromFile(file)
      navigate(`/app/screening/${result.id}/quality`)
    } finally {
      setSubmitting(false)
    }
  }

  async function handleUseSample() {
    setSubmitting(true)
    try {
      const result = await addScreeningFromSample()
      navigate(`/app/screening/${result.id}/quality`)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <AppShell area="clinician">
      <div className="mx-auto max-w-xl">
        <h1 className="mb-1 text-lg font-bold text-gray-900">Upload Fundus Image</h1>
        <p className="mb-5 text-xs text-gray-500">Upload a retinal fundus photograph to begin AI-assisted screening.</p>

        <Card>
          <CardContent>
            <div
              onDragOver={(e) => {
                e.preventDefault()
                setDragActive(true)
              }}
              onDragLeave={() => setDragActive(false)}
              onDrop={(e) => {
                e.preventDefault()
                setDragActive(false)
                handleFile(e.dataTransfer.files?.[0])
              }}
              onClick={() => inputRef.current?.click()}
              className={`flex cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed px-6 py-10 text-center transition-colors ${
                dragActive ? 'border-brand-500 bg-brand-50' : 'border-gray-300 hover:border-brand-400 hover:bg-gray-50'
              }`}
            >
              <input
                ref={inputRef}
                type="file"
                accept=".jpg,.jpeg,.png,.tif,.tiff"
                className="hidden"
                onChange={(e) => handleFile(e.target.files?.[0])}
              />
              <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-brand-100 text-brand-600">
                <UploadCloud className="h-6 w-6" />
              </div>
              <p className="text-sm font-medium text-gray-700">Drag &amp; drop image here or click to browse</p>
              <p className="mt-1 text-xs text-gray-400">JPG, PNG, TIFF (Max 10MB)</p>
            </div>

            {error && <p className="mt-2 text-xs font-medium text-danger-600">{error}</p>}

            {previewUrl && (
              <div className="mt-5">
                <p className="mb-2 flex items-center gap-1.5 text-xs font-semibold text-gray-600">
                  <ImageIcon className="h-3.5 w-3.5" /> Preview
                </p>
                <img src={previewUrl} alt="Preview" className="max-h-72 w-full rounded-lg border border-gray-200 object-contain bg-black" />
              </div>
            )}

            <Button className="mt-5 w-full" disabled={!file || submitting} onClick={handleAnalyze}>
              {submitting ? <Loader2 className="h-4 w-4 animate-spin" /> : <UploadCloud className="h-4 w-4" />}
              Upload &amp; Analyze
            </Button>

            <button
              onClick={handleUseSample}
              disabled={submitting}
              className="mt-3 flex w-full items-center justify-center gap-1.5 text-xs font-medium text-brand-600 hover:text-brand-700 disabled:opacity-50"
            >
              <Sparkles className="h-3.5 w-3.5" />
              No image on hand? Try a sample fundus image
            </button>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  )
}
