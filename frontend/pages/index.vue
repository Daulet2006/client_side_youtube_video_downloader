<script setup lang="ts">
type VideoFormat = {
  format_id: string
  ext: string | null
  quality: string
  resolution: string | null
  fps: number | null
  audio_bitrate: number | null
  filesize: number | null
  direct_url: string
  has_video: boolean
  has_audio: boolean
}

type VideoInfo = {
  title: string
  duration: number | null
  thumbnail: string | null
  webpage_url: string
  formats: VideoFormat[]
}

type Locale = 'ru' | 'kk' | 'en'
type FormatFilter = 'all' | 'combined' | 'video' | 'audio'

const config = useRuntimeConfig()

const locale = ref<Locale>('ru')
const inputUrl = ref('')
const videoInfo = ref<VideoInfo | null>(null)
const isLoading = ref(false)
const errorMessage = ref('')
const activeDownloadId = ref<string | null>(null)
const selectedFilter = ref<FormatFilter>('all')

const copy: Record<
  Locale,
  {
    languageLabel: string
    badge: string
    title: string
    subtitle: string
    description: string
    inputLabel: string
    inputPlaceholder: string
    submit: string
    loading: string
    emptyUrl: string
    noFormats: string
    loadError: string
    found: string
    openSource: string
    download: string
    preparing: string
    unknownSize: string
    unknownDuration: string
    withVideo: string
    withoutVideo: string
    withAudio: string
    withoutAudio: string
    featureOneTitle: string
    featureOneText: string
    featureTwoTitle: string
    featureTwoText: string
    featureThreeTitle: string
    featureThreeText: string
    formatsTitle: string
    bestQuality: string
    allFormats: string
    combinedFormats: string
    videoOnly: string
    audioOnly: string
    separateHint: string
    bitrate: string
    fpsLabel: string
  }
> = {
  ru: {
    languageLabel: 'Русский',
    badge: 'Бесплатно и просто',
    title: 'Скачивай видео быстро и без лишнего',
    subtitle: 'Один сайт для удобной загрузки видео по ссылке.',
    description:
      'Вставь ссылку, выбери нужное качество и скачай видео бесплатно. Без сложных шагов и лишних экранов.',
    inputLabel: 'Ссылка на видео',
    inputPlaceholder: 'Вставь ссылку YouTube сюда',
    submit: 'Показать форматы',
    loading: 'Загрузка...',
    emptyUrl: 'Сначала вставь ссылку на видео.',
    noFormats: 'Для этого видео не удалось найти доступные форматы.',
    loadError: 'Не удалось получить информацию о видео.',
    found: 'Видео найдено',
    openSource: 'Открыть на YouTube',
    download: 'Скачать',
    preparing: 'Подготовка...',
    unknownSize: 'Размер неизвестен',
    unknownDuration: 'Длительность неизвестна',
    withVideo: 'Есть видео',
    withoutVideo: 'Без видео',
    withAudio: 'Есть звук',
    withoutAudio: 'Без звука',
    featureOneTitle: 'Бесплатно',
    featureOneText: 'Используй сервис без оплаты и без лишних действий.',
    featureTwoTitle: 'Быстро',
    featureTwoText: 'Показываются все доступные варианты, включая высокое качество и отдельное аудио.',
    featureThreeTitle: 'Удобно',
    featureThreeText: 'Простая страница без перегруза, только ссылка, форматы и скачивание.',
    formatsTitle: 'Доступные форматы',
    bestQuality: 'Лучшее качество',
    allFormats: 'Все',
    combinedFormats: 'Видео + аудио',
    videoOnly: 'Только видео',
    audioOnly: 'Только аудио',
    separateHint: 'Для максимального качества часто доступны отдельные дорожки видео и аудио.',
    bitrate: 'Битрейт',
    fpsLabel: 'FPS'
  },
  kk: {
    languageLabel: 'Қазақша',
    badge: 'Тегін және оңай',
    title: 'Бейнені тез әрі артық қадамсыз жүктеп ал',
    subtitle: 'Сілтеме арқылы видеоны ыңғайлы жүктеуге арналған бір бет.',
    description:
      'Сілтемені енгіз, сапаны таңда және видеоны тегін жүктеп ал. Артық терезесіз, артық әрекетсіз.',
    inputLabel: 'Видео сілтемесі',
    inputPlaceholder: 'YouTube сілтемесін осында енгіз',
    submit: 'Форматтарды көрсету',
    loading: 'Жүктелуде...',
    emptyUrl: 'Алдымен видео сілтемесін енгіз.',
    noFormats: 'Бұл видео үшін қолжетімді форматтар табылмады.',
    loadError: 'Видео туралы ақпаратты алу мүмкін болмады.',
    found: 'Видео табылды',
    openSource: 'YouTube-та ашу',
    download: 'Жүктеп алу',
    preparing: 'Дайындалуда...',
    unknownSize: 'Өлшемі белгісіз',
    unknownDuration: 'Ұзақтығы белгісіз',
    withVideo: 'Видео бар',
    withoutVideo: 'Видео жоқ',
    withAudio: 'Дыбыс бар',
    withoutAudio: 'Дыбыс жоқ',
    featureOneTitle: 'Тегін',
    featureOneText: 'Қызметті ақысыз және артық әрекетсіз пайдалан.',
    featureTwoTitle: 'Жылдам',
    featureTwoText: 'Барлық қолжетімді нұсқалар, соның ішінде жоғары сапа мен бөлек аудио көрсетіледі.',
    featureThreeTitle: 'Ыңғайлы',
    featureThreeText: 'Қарапайым бет: тек сілтеме, форматтар және жүктеу.',
    formatsTitle: 'Қолжетімді форматтар',
    bestQuality: 'Ең жақсы сапа',
    allFormats: 'Барлығы',
    combinedFormats: 'Видео + дыбыс',
    videoOnly: 'Тек видео',
    audioOnly: 'Тек аудио',
    separateHint: 'Ең жоғары сапа үшін видео мен аудио бөлек трек ретінде жиі беріледі.',
    bitrate: 'Битрейт',
    fpsLabel: 'FPS'
  },
  en: {
    languageLabel: 'English',
    badge: 'Free and easy',
    title: 'Download videos fast without extra steps',
    subtitle: 'One clean page for downloading video from a link.',
    description:
      'Paste a link, choose the quality you want, and download the video for free. Simple flow, no extra clutter.',
    inputLabel: 'Video link',
    inputPlaceholder: 'Paste a YouTube link here',
    submit: 'Show formats',
    loading: 'Loading...',
    emptyUrl: 'Paste a video link first.',
    noFormats: 'No available formats were found for this video.',
    loadError: 'Failed to load video information.',
    found: 'Video found',
    openSource: 'Open on YouTube',
    download: 'Download',
    preparing: 'Preparing...',
    unknownSize: 'Unknown size',
    unknownDuration: 'Unknown duration',
    withVideo: 'Video included',
    withoutVideo: 'No video',
    withAudio: 'Audio included',
    withoutAudio: 'No audio',
    featureOneTitle: 'Free',
    featureOneText: 'Use the service without payment and without unnecessary steps.',
    featureTwoTitle: 'Fast',
    featureTwoText: 'See all available options, including higher quality streams and separate audio.',
    featureThreeTitle: 'Clean',
    featureThreeText: 'A simple page focused on the link, formats, and download action.',
    formatsTitle: 'Available formats',
    bestQuality: 'Best quality',
    allFormats: 'All',
    combinedFormats: 'Video + audio',
    videoOnly: 'Video only',
    audioOnly: 'Audio only',
    separateHint: 'For the highest quality, video and audio are often available as separate tracks.',
    bitrate: 'Bitrate',
    fpsLabel: 'FPS'
  }
}

const languageOptions: { code: Locale; label: string }[] = [
  { code: 'ru', label: 'RU' },
  { code: 'kk', label: 'KZ' },
  { code: 'en', label: 'EN' }
]

const t = computed(() => copy[locale.value])

const filterOptions = computed(() => [
  { key: 'all' as const, label: t.value.allFormats },
  { key: 'combined' as const, label: t.value.combinedFormats },
  { key: 'video' as const, label: t.value.videoOnly },
  { key: 'audio' as const, label: t.value.audioOnly }
])

const formatFileSize = (bytes: number | null) => {
  if (!bytes) {
    return t.value.unknownSize
  }

  const units = ['B', 'KB', 'MB', 'GB']
  let size = bytes
  let index = 0

  while (size >= 1024 && index < units.length - 1) {
    size /= 1024
    index += 1
  }

  return `${size.toFixed(size >= 10 || index === 0 ? 0 : 1)} ${units[index]}`
}

const formatDuration = (seconds: number | null) => {
  if (!seconds && seconds !== 0) {
    return t.value.unknownDuration
  }

  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60

  if (hours > 0) {
    return `${hours}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`
  }

  return `${minutes}:${String(secs).padStart(2, '0')}`
}

const resetState = () => {
  errorMessage.value = ''
  videoInfo.value = null
  selectedFilter.value = 'all'
}

const loadVideoInfo = async () => {
  if (!inputUrl.value.trim()) {
    errorMessage.value = t.value.emptyUrl
    return
  }

  isLoading.value = true
  resetState()

  try {
    const response = await $fetch<VideoInfo>('/api/video-info', {
      baseURL: config.public.apiBase,
      method: 'POST',
      body: { url: inputUrl.value.trim() }
    })

    if (!response.formats.length) {
      errorMessage.value = t.value.noFormats
      return
    }

    videoInfo.value = response
  } catch (error) {
    errorMessage.value =
      error instanceof Error ? error.message : t.value.loadError
  } finally {
    isLoading.value = false
  }
}

const triggerBrowserDownload = (url: string, fileName: string) => {
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = fileName
  anchor.rel = 'noopener noreferrer'
  anchor.target = '_blank'
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
}

const downloadFormat = async (format: VideoFormat) => {
  const baseName = (videoInfo.value?.title || 'youtube-video')
    .replace(/[^\w\d-_ ]+/g, '')
    .trim()
    .replace(/\s+/g, '-')

  const fileName = `${baseName || 'youtube-video'}-${format.format_id}.${format.ext || 'mp4'}`
  activeDownloadId.value = format.format_id

  try {
    const response = await fetch(format.direct_url, { mode: 'cors' })
    if (!response.ok) {
      throw new Error('Stream request failed')
    }

    const blob = await response.blob()
    const blobUrl = URL.createObjectURL(blob)
    triggerBrowserDownload(blobUrl, fileName)
    window.setTimeout(() => URL.revokeObjectURL(blobUrl), 30_000)
  } catch {
    triggerBrowserDownload(format.direct_url, fileName)
  } finally {
    activeDownloadId.value = null
  }
}

const sortedFormats = computed(() =>
  [...(videoInfo.value?.formats || [])].sort((left, right) => {
    const leftScore = Number(left.has_video && left.has_audio)
    const rightScore = Number(right.has_video && right.has_audio)

    if (leftScore !== rightScore) {
      return rightScore - leftScore
    }

    return (
      (parseInt(right.resolution || '0', 10) || 0) - (parseInt(left.resolution || '0', 10) || 0) ||
      (right.audio_bitrate || 0) - (left.audio_bitrate || 0) ||
      (right.fps || 0) - (left.fps || 0) ||
      (right.filesize || 0) - (left.filesize || 0)
    )
  })
)

const filteredFormats = computed(() => {
  if (selectedFilter.value === 'combined') {
    return sortedFormats.value.filter((format) => format.has_video && format.has_audio)
  }

  if (selectedFilter.value === 'video') {
    return sortedFormats.value.filter((format) => format.has_video && !format.has_audio)
  }

  if (selectedFilter.value === 'audio') {
    return sortedFormats.value.filter((format) => !format.has_video && format.has_audio)
  }

  return sortedFormats.value
})
</script>

<template>
  <main class="page-shell">
    <section class="topbar">
      <div class="brand-block">
        <p class="brand-name">TubeLoad</p>
        <p class="brand-subtitle">{{ t.subtitle }}</p>
      </div>

      <div class="language-switcher" :aria-label="t.languageLabel">
        <button
          v-for="item in languageOptions"
          :key="item.code"
          type="button"
          class="language-pill"
          :class="{ active: locale === item.code }"
          @click="locale = item.code"
        >
          {{ item.label }}
        </button>
      </div>
    </section>

    <section class="hero-card">
      <p class="eyebrow">{{ t.badge }}</p>
      <h1>{{ t.title }}</h1>
      <p class="lead">{{ t.description }}</p>

      <div class="feature-row">
        <article class="feature-chip">
          <strong>{{ t.featureOneTitle }}</strong>
          <span>{{ t.featureOneText }}</span>
        </article>
        <article class="feature-chip">
          <strong>{{ t.featureTwoTitle }}</strong>
          <span>{{ t.featureTwoText }}</span>
        </article>
        <article class="feature-chip">
          <strong>{{ t.featureThreeTitle }}</strong>
          <span>{{ t.featureThreeText }}</span>
        </article>
      </div>

      <form class="search-panel" @submit.prevent="loadVideoInfo">
        <label class="field-label" for="video-url">{{ t.inputLabel }}</label>
        <div class="input-row">
          <input
            id="video-url"
            v-model="inputUrl"
            type="url"
            :placeholder="t.inputPlaceholder"
            autocomplete="off"
          />
          <button type="submit" :disabled="isLoading">
            {{ isLoading ? t.loading : t.submit }}
          </button>
        </div>
      </form>

      <p v-if="errorMessage" class="message error">{{ errorMessage }}</p>
    </section>

    <section v-if="videoInfo" class="result-card">
      <div class="video-meta">
        <img
          v-if="videoInfo.thumbnail"
          :src="videoInfo.thumbnail"
          :alt="videoInfo.title"
          class="thumb"
        />

        <div class="meta-copy">
          <p class="meta-kicker">{{ t.found }}</p>
          <h2>{{ videoInfo.title }}</h2>
          <p>{{ formatDuration(videoInfo.duration) }}</p>
          <p class="quality-note">{{ t.separateHint }}</p>
          <a :href="videoInfo.webpage_url" target="_blank" rel="noreferrer">{{ t.openSource }}</a>
        </div>
      </div>

      <div class="format-toolbar">
        <h3 class="formats-heading">{{ t.formatsTitle }}</h3>
        <div class="filter-row">
          <button
            v-for="filter in filterOptions"
            :key="filter.key"
            type="button"
            class="filter-pill"
            :class="{ active: selectedFilter === filter.key }"
            @click="selectedFilter = filter.key"
          >
            {{ filter.label }}
          </button>
        </div>
      </div>

      <div class="formats-grid">
        <article v-for="format in filteredFormats" :key="format.format_id" class="format-card">
          <div>
            <div class="format-topline">
              <p class="format-title">{{ format.quality }}</p>
              <span
                v-if="format.resolution && format.has_video && format.has_audio"
                class="format-badge"
              >
                {{ t.bestQuality }}
              </span>
            </div>
            <p class="format-meta">
              {{ format.has_video ? t.withVideo : t.withoutVideo }} /
              {{ format.has_audio ? t.withAudio : t.withoutAudio }}
            </p>
            <p v-if="format.fps" class="format-meta">{{ t.fpsLabel }}: {{ format.fps }}</p>
            <p v-if="format.audio_bitrate" class="format-meta">
              {{ t.bitrate }}: {{ format.audio_bitrate }} kbps
            </p>
            <p class="format-meta">{{ formatFileSize(format.filesize) }}</p>
          </div>

          <button
            class="download-button"
            :disabled="activeDownloadId === format.format_id"
            @click="downloadFormat(format)"
          >
            {{ activeDownloadId === format.format_id ? t.preparing : t.download }}
          </button>
        </article>
      </div>
    </section>
  </main>
</template>
