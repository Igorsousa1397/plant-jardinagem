# Banco (Supabase)

## Criar o schema
1. Abra o projeto no painel do Supabase → **SQL Editor** → **New query**.
2. Cole o conteúdo de `migrations/0001_init.sql` e clique **Run**.
   - Cria as tabelas `clientes` e `relatorios`, o enum de status, índices,
     trigger de `updated_at`, RLS e o bucket de Storage `relatorios` (fotos).
3. (Opcional) Cole `seed.sql` e **Run** uma vez para popular clientes + 2 relatórios.

## Conectar o app
Em **Project Settings → API**, copie *Project URL* e *anon public key* para `.env.local`:
```
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...
```

## RLS
As policies liberam acesso total para usuários **autenticados**. Como a tela de login
ainda não existe, para testar sem auth descomente o bloco **DEV** no final do
`0001_init.sql` (libera o papel `anon`) — e remova antes de produção.

## Via CLI (alternativa)
Com a Supabase CLI e o projeto linkado: `supabase db push`.

## Login (Supabase Auth)
O app agora exige login e a RLS libera só usuários **autenticados** —
então **não** use o bloco DEV/anon.

Crie seu usuário:
1. **Authentication → Users → Add user**.
2. Preencha e-mail e senha e marque **Auto Confirm User** (entra sem confirmar e-mail).
3. Use esse e-mail/senha na tela `/login` do app.

(Opcional) Para permitir cadastro pela tela: Authentication → Providers → Email,
e desligue "Confirm email" no ambiente de dev.
