# Plano de Treino · Basquete

Link principal (`/`) = login do professor. Cada aluno recebe um link pessoal (`/?a=TOKEN`), sem login.

## 1. Supabase (JÁ FEITO: projeto `treino-basquete`, schema aplicado e `index.html` já configurado)
Falta apenas: passos 3, 4 e 5 abaixo e o GitHub (seção 3).

1. Crie um projeto em supabase.com.
2. **SQL Editor** → cole `supabase/schema.sql` → Run.
3. **Authentication → Users → Add user**: e-mail e senha do professor.
4. **Authentication → Sign In / Providers**: desative *Allow new users to sign up*.
5. No SQL Editor, torne o usuário professor (troque o e-mail):
   `insert into public.professores select id from auth.users where email = 'professor@email.com';`
6. **Project Settings → API**: copie *Project URL* e a chave *anon public*.

## 2. Configurar
Abra `index.html` e preencha `SUPABASE_URL` e `SUPABASE_KEY` (início do `<script>`).
A chave anon é pública por design; a segurança vem das regras (RLS) do `schema.sql`. Nunca use a `service_role`.

## 3. GitHub Pages
```
git init && git add . && git commit -m "Plano de treino"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/basquete-treino.git
git push -u origin main
```
No repositório: **Settings → Pages → Deploy from a branch → main / root**.
Em **Supabase → Authentication → URL Configuration**, coloque a URL do Pages em *Site URL*.

## Uso
- Professor: abre o link principal, entra, vai em **Painel da turma → Cadastrar aluno**.
- **Copiar link do aluno** e enviar por WhatsApp.
- Em **Treino**, o seletor "Enviando treino para" escolhe turma ou aluno.
- Remover um aluno invalida o link dele. Para só suspender, ponha `ativo = false` na tabela `alunos`.
