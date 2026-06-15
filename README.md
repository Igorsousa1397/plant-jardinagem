# Plant Jardinagem — App

PWA da Plant Jardinagem e Paisagismo para tirar do papel as quatro dores do dia a dia:
**relatórios** (antes/depois), **propostas**, **controle financeiro** e **ponto** dos funcionários fixos.

Stack: **Next.js 14 (App Router) · TypeScript · Tailwind · Supabase**.

## Rodar localmente

```bash
npm install
cp .env.example .env.local   # preencha as chaves do Supabase
npm run dev
```

Abra http://localhost:3000

## Estrutura

```
src/
├─ app/
│  ├─ page.tsx                 → escolha de papel (provisória, antes do login)
│  ├─ admin/                   → visão ADMIN (Claiton) — tem todas as telas
│  │  ├─ layout.tsx            → shell + navegação inferior + ReportsProvider
│  │  ├─ relatorios/           → lista · /novo · /[id] (preview do síndico)
│  │  ├─ propostas/  (em breve)
│  │  ├─ financeiro/ (em breve)
│  │  └─ ponto/      (em breve — admin valida as batidas do dia)
│  └─ campo/                   → visão FUNCIONÁRIO — só o ponto
│     └─ ponto/     (em breve)
├─ components/
│  ├─ ui/                      → Badge, Button, Chip, Field, BottomNav, EmBreve
│  └─ relatorios/              → ReportCard, ReportForm, ReportPreview, GardenSVG, store
├─ lib/
│  ├─ supabase/                → client (browser) e server
│  ├─ constants.ts             → serviços, equipamentos, condomínios, status, dados da empresa
│  └─ utils.ts
├─ types/index.ts              → Report, Status, Papel
└─ data/seed.ts                → relatórios de exemplo (trocar por Supabase)
```

## Design system

Os tokens (cores `verde-*`, `dourado`, `salvia`, neutros, semânticos; fontes Fraunces / Hanken Grotesk / IBM Plex Mono; sombras `s1–s3`) ficam em `tailwind.config.ts` e são usados via classes utilitárias.

## Estado do módulo de relatório

Hoje os relatórios vivem em memória (`ReportsProvider` + `data/seed.ts`) para o protótipo navegar.
Para produção, troque por Supabase:

1. Tabela `relatorios` (campos = `types/Report`).
2. Lista e preview viram Server Components lendo via `lib/supabase/server`.
3. Fotos vão pro Supabase Storage; o `FileReader`/dataURL do formulário passa a ser upload.
4. `Gerar PDF` numa Route Handler (`@react-pdf/renderer` ou Puppeteer); `Enviar ao síndico` abre `wa.me/<telefone>?text=`.

## Papéis

- **admin** → `/admin/*` (relatórios, propostas, financeiro, ponto)
- **funcionario** → `/campo/ponto` (apenas o ponto)

Ligar à autenticação do Supabase e redirecionar pelo perfil no login.
