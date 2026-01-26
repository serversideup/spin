export function useAssetUrl(path: string | undefined | null): string {
  if (!path) {
    return ''
  }

  const config = useRuntimeConfig()
  const baseUrl = config.public.baseUrl || ''

  // If path already starts with http(s), return as-is
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path
  }

  // Remove leading slash from path if present
  const cleanPath = path.startsWith('/') ? path.slice(1) : path

  // Combine base URL with path
  return `${baseUrl}/${cleanPath}`
}
