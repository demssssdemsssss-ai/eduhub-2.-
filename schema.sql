-- EduHub 2.0 starter schema for Supabase.
-- Run in Supabase SQL Editor in a new project.
-- Review/test policies before using with real student data.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  role text not null check (role in ('teacher','student','parent')),
  student_id text unique,
  teacher_id text unique,
  subject_department text,
  school text,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  subject text not null default '',
  section text not null default '',
  class_code text not null unique,
  archived boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.class_members (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(class_id, student_id)
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null,
  subject text not null default '',
  description text not null default '',
  content text not null default '',
  published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null,
  subject text not null default '',
  question text not null,
  correct_answer text not null,
  points integer not null default 10 check (points > 0),
  published boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  answer text not null,
  score numeric not null default 0,
  max_score numeric not null,
  submitted_at timestamptz not null default now()
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  activity_id uuid references public.activities(id) on delete set null,
  title text not null,
  subject text not null default '',
  score numeric not null default 0,
  max_score numeric not null default 10,
  created_at timestamptz not null default now()
);

create table if not exists public.parent_link_codes (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  code text not null unique,
  expires_at timestamptz not null,
  used boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.parent_student_links (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active' check (status in ('active','revoked')),
  created_at timestamptz not null default now(),
  unique(parent_id, student_id)
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  title text not null,
  body text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_class_members_student on public.class_members(student_id);
create index if not exists idx_classes_teacher on public.classes(teacher_id);
create index if not exists idx_lessons_class on public.lessons(class_id);
create index if not exists idx_activities_class on public.activities(class_id);
create index if not exists idx_grades_student on public.grades(student_id);
create index if not exists idx_parent_links_parent on public.parent_student_links(parent_id);
create index if not exists idx_parent_links_student on public.parent_student_links(student_id);
create index if not exists idx_notifications_user on public.notifications(user_id);

-- Helper functions for policies. SECURITY DEFINER avoids recursive RLS lookups.
create or replace function public.current_role()
returns text language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.is_class_teacher(class_uuid uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.classes c where c.id = class_uuid and c.teacher_id = auth.uid()) $$;

create or replace function public.is_class_member(class_uuid uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.class_members m where m.class_id = class_uuid and m.student_id = auth.uid()) $$;

create or replace function public.is_parent_of(student_uuid uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.parent_student_links l where l.parent_id = auth.uid() and l.student_id = student_uuid and l.status = 'active') $$;

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.class_members enable row level security;
alter table public.lessons enable row level security;
alter table public.activities enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.grades enable row level security;
alter table public.parent_link_codes enable row level security;
alter table public.parent_student_links enable row level security;
alter table public.announcements enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;

-- Profiles: own profile, teacher sees students in own classes, parents see linked child.
create policy "profiles_select_own_teacher_or_linked" on public.profiles for select to authenticated
using (
  id = auth.uid()
  or exists (select 1 from public.classes c join public.class_members m on m.class_id=c.id where c.teacher_id=auth.uid() and m.student_id=profiles.id)
  or public.is_parent_of(id)
);
create policy "profiles_insert_self" on public.profiles for insert to authenticated with check (id=auth.uid());
create policy "profiles_update_self" on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());

-- Classes: teachers own them; enrolled students can read; linked parents can read child's classes.
create policy "classes_read_authorized" on public.classes for select to authenticated
using (teacher_id=auth.uid() or public.is_class_member(id) or exists(select 1 from public.class_members m where m.class_id=classes.id and public.is_parent_of(m.student_id)));
create policy "classes_teacher_insert" on public.classes for insert to authenticated
with check (teacher_id=auth.uid() and public.current_role()='teacher');
create policy "classes_teacher_update" on public.classes for update to authenticated
using (teacher_id=auth.uid()) with check (teacher_id=auth.uid());
create policy "classes_teacher_delete" on public.classes for delete to authenticated using (teacher_id=auth.uid());

-- Class membership: teacher manages roster, student can see own membership and join only a valid code via app.
create policy "members_read_authorized" on public.class_members for select to authenticated
using (student_id=auth.uid() or public.is_class_teacher(class_id) or public.is_parent_of(student_id));
create policy "members_student_join" on public.class_members for insert to authenticated
with check (student_id=auth.uid() and public.current_role()='student' and exists(select 1 from public.classes c where c.id=class_id and c.archived=false));
create policy "members_teacher_delete" on public.class_members for delete to authenticated using (public.is_class_teacher(class_id));

-- Lessons: teacher manages own class lessons; enrolled students and linked parents can read published lessons.
create policy "lessons_read_authorized" on public.lessons for select to authenticated
using (teacher_id=auth.uid() or (published=true and (public.is_class_member(class_id) or exists(select 1 from public.class_members m where m.class_id=lessons.class_id and public.is_parent_of(m.student_id)))));
create policy "lessons_teacher_insert" on public.lessons for insert to authenticated
with check (teacher_id=auth.uid() and public.is_class_teacher(class_id));
create policy "lessons_teacher_update" on public.lessons for update to authenticated
using (teacher_id=auth.uid()) with check (teacher_id=auth.uid());
create policy "lessons_teacher_delete" on public.lessons for delete to authenticated using (teacher_id=auth.uid());

-- Activities: student sees published work; teacher manages their own activities.
create policy "activities_read_authorized" on public.activities for select to authenticated
using (teacher_id=auth.uid() or (published=true and (public.is_class_member(class_id) or exists(select 1 from public.class_members m where m.class_id=activities.class_id and public.is_parent_of(m.student_id)))));
create policy "activities_teacher_insert" on public.activities for insert to authenticated
with check (teacher_id=auth.uid() and public.is_class_teacher(class_id));
create policy "activities_teacher_update" on public.activities for update to authenticated using (teacher_id=auth.uid()) with check (teacher_id=auth.uid());
create policy "activities_teacher_delete" on public.activities for delete to authenticated using (teacher_id=auth.uid());

-- Attempts: students own their attempts; teachers of the class can view; parents of student can view.
create policy "attempts_read_authorized" on public.quiz_attempts for select to authenticated
using (student_id=auth.uid() or exists(select 1 from public.activities a where a.id=activity_id and public.is_class_teacher(a.class_id)) or public.is_parent_of(student_id));
create policy "attempts_student_insert" on public.quiz_attempts for insert to authenticated
with check (student_id=auth.uid() and public.current_role()='student');

-- Grades: students and parents can read, teachers can read/write grades for their classes. No student or parent grade writes.
create policy "grades_read_authorized" on public.grades for select to authenticated
using (student_id=auth.uid() or public.is_class_teacher(class_id) or public.is_parent_of(student_id));
create policy "grades_teacher_insert" on public.grades for insert to authenticated
with check (public.is_class_teacher(class_id) and public.current_role()='teacher');
create policy "grades_teacher_update" on public.grades for update to authenticated
using (public.is_class_teacher(class_id)) with check (public.is_class_teacher(class_id));
create policy "grades_teacher_delete" on public.grades for delete to authenticated using (public.is_class_teacher(class_id));

-- Link codes: student can generate/read own codes; app validates codes. Parent must not read other codes.
create policy "link_codes_student_manage" on public.parent_link_codes for all to authenticated
using (student_id=auth.uid()) with check (student_id=auth.uid());
create policy "parent_links_read_authorized" on public.parent_student_links for select to authenticated
using (parent_id=auth.uid() or student_id=auth.uid());
create policy "parent_links_parent_insert" on public.parent_student_links for insert to authenticated
with check (parent_id=auth.uid() and public.current_role()='parent');
create policy "parent_links_student_revoke" on public.parent_student_links for update to authenticated
using (student_id=auth.uid()) with check (student_id=auth.uid());

-- Announcements: teacher manages own class; enrolled students/linked parents read.
create policy "announcements_read_authorized" on public.announcements for select to authenticated
using (teacher_id=auth.uid() or public.is_class_member(class_id) or exists(select 1 from public.class_members m where m.class_id=announcements.class_id and public.is_parent_of(m.student_id)));
create policy "announcements_teacher_insert" on public.announcements for insert to authenticated
with check (teacher_id=auth.uid() and public.is_class_teacher(class_id));
create policy "announcements_teacher_update" on public.announcements for update to authenticated using (teacher_id=auth.uid()) with check (teacher_id=auth.uid());
create policy "announcements_teacher_delete" on public.announcements for delete to authenticated using (teacher_id=auth.uid());

-- Messages: only sender and recipient can see; sender can create messages as self.
create policy "messages_read_participants" on public.messages for select to authenticated
using (sender_id=auth.uid() or recipient_id=auth.uid());
create policy "messages_insert_sender" on public.messages for insert to authenticated
with check (sender_id=auth.uid());
create policy "messages_update_recipient" on public.messages for update to authenticated
using (recipient_id=auth.uid()) with check (recipient_id=auth.uid());

create policy "notifications_read_own" on public.notifications for select to authenticated using (user_id=auth.uid());
create policy "notifications_update_own" on public.notifications for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
